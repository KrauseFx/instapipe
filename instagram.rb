require 'net/http'
require 'net/https'
require 'open-uri'
require 'pry'
require 'json'
require 'telegram/bot'
require_relative "./database"

module Instapipe
  class Instagram
    attr_accessor :access_token
    attr_accessor :user_id
    attr_accessor :telegram_client

    def initialize(access_token:, user_id:)
      self.access_token = access_token
      self.user_id = user_id
      self.telegram_client = ::Telegram::Bot::Client.new(ENV["TELEGRAM_TOKEN"])
    end

    def stories(telegram_chat_id:)
      puts "Fetching latest stories..."
      uri = URI("https://graph.facebook.com/v14.0/17841401712160068/stories")
      uri.query = URI.encode_www_form(
        fields: "fields=caption,media_product_type,media_url,ig_id,thumbnail_url,timestamp,username,children,permalink",
        access_token: self.access_token
      )
      begin
        res = Net::HTTP.get_response(uri)
        parsed = JSON.parse(res.body)
        parsed.fetch("data").each do |story|
          parse_story(story, telegram_chat_id)
        end
      rescue => ex
        puts ex.message
        puts ex.backtrace.join("\n")
        binding.pry
        # self.telegram_client.api.send_message(
        #   chat_id: telegram_chat_id,
        #   text: "Instagram API error, please investigate"
        # )

        raise "error #{res}"
      end
      puts res
    end

    def parse_story(story, telegram_chat_id)
      # [{"media_product_type"=>"STORY",
      #   "media_url"=>
      #    "https://scontent-frx5-2.cdninstagram.com/v/t51.29350-15/298198352_606175957556744_6641839168962727256_n.jpg?_nc_cat=103&ccb=1-7&_nc_sid=8ae9d6&_nc_ohc=A5Ihp1UcLwAAX8cd8nl&_nc_ht=scontent-frx5-2.cdninstagram.com&edm=AB9oSrcEAAAA&oh=00_AT_cZwUR-XBlo3HC_lwx8ngOL3noVIhNHecLHTauXeqHng&oe=62F6C369",
      #   "like_count"=>0,
      #   "timestamp"=>"2022-08-08T21:22:38+0000",
      #   "username"=>"krausefx",
      #   "permalink"=>"https://instagram.com/stories/krausefx/2900560353990676495",
      #   "id"=>"17870665568746523"}],
      new_entry = {}
      
      # First, download the image asset
      file_path = File.join("/tmp/", story["ig_id"])
      File.write(file_path, URI.open(story["media_url"]).read)

      # Detect if it's a video or photo that was posted
      file_type = `file -I #{file_path}`
      if file_type.include?("image/jpeg")
        new_entry["is_video"] = false
      elsif file_type.include?("video/mp4")
        new_entry["is_video"] = true
      else
        puts "Unknown file type #{file_type}: file_type"
        binding.pry
      end

      # Fill in the basic metadata
      new_entry.merge!({
        ig_id: story["ig_id"],
        timestamp: Time.parse(story["timestamp"]).to_i,
        username: story["username"],
        permalink: story["permalink"],
        caption: story["caption"],
      })
      
      if new_entry["is_video"]
        # TODO
        puts "Uploading video... this might take a little longer"
        self.telegram_client.api.send_video(
          chat_id: telegram_chat_id,
          video: Faraday::UploadIO.new(file_path, 'video/mp4')
        )
      else 
        self.telegram_client.api.send_photo(
          chat_id: telegram_chat_id,
          photo: Faraday::UploadIO.new(file_path, 'image/jpg')
        )
      end

      extension = new_entry["is_video"] ? ".mp4" : ".jpg"
      binding.pry
      output_path = File.join(user_id, "#{new_entry['id']}#{extension}")
      puts "uploading file to Google Cloud #{output_path}"
      created_file = Database.file_storage_bucket.create_file(file_path, output_path)

      new_entry[:signed_url] = created_file.signed_url(method: "GET", expires: 24 * 60 * 60) # expires in 24h
      new_entry[:bucket_path] = output_path
      
      binding.pry
      # only after successfully posting it, store in db
      Database.database[:stories].insert(new_entry)

      binding.pry
      puts 'hi'
    end
  end
end

if __FILE__ == $0
  instagram = Instapipe::Instagram.new(
    access_token: ENV.fetch('INSTAGRAM_ACCESS_TOKEN'),
    user_id: ENV.fetch("IG_BUSINESS_USER_ID")
  )
  puts instagram.stories(telegram_chat_id: ENV["TELEGRAM_CHAT_ID"])
end