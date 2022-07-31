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

    def stories(user_id:, chat_id:)
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
      begin
        res = http.request(req)
      rescue => ex
        puts ex.message
        self.telegram_client.api.send_message(
          chat_id: chat_id,
          text: "Instagram API key expired, please refresh the `sessionid`"
        )

        raise "error #{res}"
      end
      puts res.to_hash["location"]
      if res.code.to_i == 302 && (res.to_hash["location"].first || "").include?("unblock")
        # API key expired
        puts "Instagram API key expired, please refresh the `sessionid` and the `ds_user_id`"
        self.telegram_client.api.send_message(
          chat_id: chat_id,
          text: "Instagram API key expired, please refresh the `sessionid`"
        )

        raise "error #{res}"
      end
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
        if Array(item["story_locations"]).count > 0
          loc = item["story_locations"].first["location"]
          version["location"] = {
            name: loc["name"],
            lat: loc["lat"],
            lng: loc["lng"]
          }
        end

        version["timestamp"] = item["taken_at"] # TODO: investigate if that's the right one, alternative is `device_timestamp`
        if Database.database[:stories].where(ig_id: version["id"]).count > 0
          nil # we already have this in our db
        else
          version # collect those
        end
      end.compact

      puts "Storing #{items.count} in database and send it via Telegram"
      items.each do |item|
        puts "Uploading #{item}"
        file_path = File.join("/tmp/", item["id"])
        File.write(file_path, open(item["url"]).read)

        begin
          # TODO: Obviously refactor to separate Telegram from rest
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

          extension = item["is_video"] ? ".mp4" : ".jpg"
          output_path = File.join(user_id, "#{item['id']}#{extension}")
          puts "uploading file to Google Cloud #{output_path}"
          created_file = Database.file_storage_bucket.create_file(file_path, output_path)

          signed_url = created_file.signed_url(method: "GET", expires: 24 * 60 * 60) # expires in 24h

          # only after successfully posting it, store in db
          Database.database[:stories].insert({
            ig_id: item["id"],
            user_id: user_id,
            signed_url: signed_url,
            bucket_path: output_path,
            height: item["height"],
            width: item["width"],
            timestamp: item["timestamp"],
            is_video: item["is_video"],
            location: item["location"].to_json
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
