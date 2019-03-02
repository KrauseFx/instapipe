require 'net/http'
require 'net/https'
require 'json'
require 'telegram/bot'
require 'open-uri'
require_relative "./database"

module Instapipe
  class Instapipe
    attr_accessor :sessionid
    attr_accessor :ds_user_id
    attr_accessor :telegram_client

    def initialize(sessionid:, ds_user_id:)
      self.sessionid = sessionid
      self.ds_user_id = ds_user_id

      self.telegram_client = ::Telegram::Bot::Client.new(ENV["TELEGRAM_TOKEN"])
    end

    def stories(user_id:)
      uri = URI("https://i.instagram.com/api/v1/feed/user/#{user_id}/reel_media/")

      # Create client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      # http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # Create Request
      req =  Net::HTTP::Get.new(uri)
      req.add_field "Cookie", "sessionid=#{self.sessionid}; ds_user_id=#{self.ds_user_id}"
      req.add_field "User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_2 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13F69 Instagram 8.4.0 (iPhone7,2; iPhone OS 9_3_2; nb_NO; nb-NO; scale=2.00; 750x1334"

      # Fetch Request
      res = http.request(req)
      raise "Error #{res}" unless res.code.to_i == 200
      response = JSON.parse(res.body)

      items = response["items"].collect do |item|
        # Check if it's a video, long term we should obviously check the type
        is_video = false
        version = item.fetch("video_versions", [])[0]
        if version
          # good enough for now
          is_video = true
        else
          version = item["image_versions2"]["candidates"][0] # best resolution version
        end

        version["is_video"] = is_video
        version["id"] = item["id"]
        version["timestamp"] = item["taken_at"] # TODO: investigate if that's the right one, alternative is `device_timestamp`
        if Database.database[:stories].where(ig_id: version["id"])
          nil # we already have this in our db
        else
          version # collect those
        end
      end.compact

      puts "Storing #{items.count} in database and send it via Telegram"
      chat_id = ENV["TELEGRAM_CHAT_ID"]
      items.each do |item|
        puts "Uploading #{item}"
        file_path = File.join("/tmp/", item["id"])
        File.write(file_path, open(item["url"]).read)

        begin
          if item["is_video"]
            puts "Uploading video... this might take a little longer"
            self.telegram_client.api.send_video(
              chat_id: chat_id,
              video: Faraday::UploadIO.new(file_path, 'video/mp4')
            )
          else
            self.telegram_client.api.send_photo(
              chat_id: chat_id,
              photo: Faraday::UploadIO.new(file_path, 'image/jpg')
            )
          end

          # only after successfully posting it, store in db
          Database.database[:stories].insert({
            ig_id: item["id"],
            url: item["url"],
            height: item["height"],
            width: item["width"],
            timestamp: item["timestamp"],
            is_video: item["is_video"]
          })
        rescue => ex
          puts ex
        end
      end

    rescue StandardError => e
      puts "HTTP Request failed (#{e.message}: #{e})"
    end
  end
end

instapipe = Instapipe::Instapipe.new(sessionid: ENV["SESSIONID"], ds_user_id: ENV["DS_USER_ID"])
response = instapipe.stories(user_id: ENV["USER_TO_WATCH"])
puts response
