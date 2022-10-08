require 'net/http'
require 'marcel'
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

    def initialize(fb_token_entry:)
      self.access_token = fb_token_entry.fetch(:long_lived_access_token)
      self.user_id = fb_token_entry.fetch(:user_id)
      self.telegram_client = ::Telegram::Bot::Client.new(ENV["TELEGRAM_TOKEN"])
    end

    def stories(telegram_chat_id:)
      puts "Fetching latest stories..."
      puts "No Telegram Chat ID provided for user #{user_id}" unless telegram_chat_id
      uri = URI("https://graph.facebook.com/v14.0/#{user_id}/stories")
      uri.query = URI.encode_www_form(
        fields: "caption,media_product_type,media_url,thumbnail_url,timestamp,username,children,permalink,ig_id",
        access_token: self.access_token
      )
      begin
        res = Net::HTTP.get_response(uri)
        parsed = JSON.parse(res.body)
        if parsed["error"]
          puts parsed
          self.telegram_client.api.send_message(
            chat_id: telegram_chat_id,
            text: "Instagram API for Stories error: #{parsed["error"]["message"]}"
          ) if telegram_chat_id
          return
        end
        parsed.fetch("data").sort_by { |story| story["timestamp"] }.each do |story| # starting with the oldest
          parse_story(story, telegram_chat_id)
        end
      rescue => ex
        puts ex.message
        puts ex.backtrace.join("\n")
        self.telegram_client.api.send_message(
          chat_id: telegram_chat_id,
          text: "Instagram API error, please investigate"
        ) if telegram_chat_id

        raise "error #{res}"
      end
    end

    def posts(telegram_chat_id:)
      puts "Fetching latest posts..."
      puts "No Telegram Chat ID provided for user #{user_id}" unless telegram_chat_id
      uri = URI("https://graph.facebook.com/v14.0/#{user_id}/media")
      uri.query = URI.encode_www_form(
        fields: "caption,id,username,ig_id,like_count,comments_count,media_product_type,media_type,media_url,permalink,thumbnail_url,timestamp,comments,children{media_url,thumbnail_url,ig_id,media_type}",
        access_token: self.access_token
      )
      begin
        res = Net::HTTP.get_response(uri)
        parsed = JSON.parse(res.body)
        if parsed["error"]
          puts parsed
          self.telegram_client.api.send_message(
            chat_id: telegram_chat_id,
            text: "Instagram API for Posts error: #{parsed["error"]["message"]}"
          ) if telegram_chat_id
          return
        end
        parsed.fetch("data").sort_by { |post| post["timestamp"] }.each do |post| # starting with the oldest
          parse_post(post, telegram_chat_id)
        end
      rescue => ex
        puts ex.message
        puts ex.backtrace.join("\n")
        self.telegram_client.api.send_message(
          chat_id: telegram_chat_id,
          text: "Instagram API error, please investigate"
        ) if telegram_chat_id

        raise "error #{res}"
      end
    end

    def parse_story(story, telegram_chat_id)
      # First check, if we already have that specific story stored
      if Database.database[:stories].where(ig_id: story["ig_id"]).count > 0
        puts "Story with ID #{story["ig_id"]} already stored"
        return nil
      end
      if story["media_url"].nil?
        puts "No media URL for this story, this might be a video with a sound tag on, so we don't seem to get access"
        return nil
      end
      res = download_and_store_asset(
        ig_id: story["ig_id"], 
        file_name_to_use: story["id"], 
        media_url: story["media_url"], 
        expires: 24 * 60 * 60,
        prefix_folder: nil
      )
      return if res.nil?

      # Fill in the basic metadata
      new_entry = {
        ig_id: story["ig_id"],
        timestamp: Time.parse(story["timestamp"]).to_i,
        username: story["username"],
        permalink: story["permalink"],
        caption: story["caption"],
        user_id: self.user_id,
        is_video: file_type(res[:file_path]) == :video,
        signed_url: res[:signed_url],
        bucket_path: res[:output_path]
      }
      
      if new_entry[:is_video]
        puts "Uploading video... this might take a little longer"
        self.telegram_client.api.send_video(
          chat_id: telegram_chat_id,
          video: Faraday::UploadIO.new(res[:file_path], 'video/mp4')
        ) if telegram_chat_id
      else 
        self.telegram_client.api.send_photo(
          chat_id: telegram_chat_id,
          photo: Faraday::UploadIO.new(res[:file_path], 'image/jpg')
        ) if telegram_chat_id
      end

      # only after successfully posting it, store in db
      Database.database[:stories].insert(new_entry)
      puts "Completed"
    end

    def parse_post(post, telegram_chat_id)
      # posts with multiple images/video have `children`, single media posts don't
      images_to_parse = nil
      if Array(post["children"]).count > 0
        images_to_parse = post["children"]["data"]
      else
        # same keys, but on the top level of the node
        images_to_parse = [post]
      end

      base_entry = {
        caption: post["caption"],
        media_product_type: post["media_product_type"],
        permalink: post["permalink"],
        timestamp: Time.parse(post["timestamp"]).to_i,
        username: post["username"],
        user_id: self.user_id,
        ig_id: post["ig_id"]
      }
      entries_to_post_to_telegram = []
      images_to_parse.each_with_index do |node, index|
        existing_entries_query = Database.database[:posts].where(ig_id: post["ig_id"], node_ig_id: node["ig_id"])
        if existing_entries_query.count > 0
          # Only update the number of likes/comments of the post
          puts "Updating like/comments count for post #{post["ig_id"]}"
          existing_entries_query.update(
            like_count: post["like_count"],
            comments_count: post["comments_count"],
            caption: base_entry["caption"] # as the caption might have changed
          )
          next
        end

        res = download_and_store_asset(
          ig_id: node["ig_id"],
          file_name_to_use: [post["id"], node["id"]].join("-"),
          media_url: node["media_url"],
          expires: 5 * 365 * 24 * 60 * 60,
          prefix_folder: "posts"
        )
        next if res.nil?
        new_entry = base_entry.dup.merge(
          is_video: file_type(res[:file_path]) == :video,
          signed_url: res[:signed_url],
          bucket_path: res[:output_path],
          node_id: node["id"],
          node_ig_id: node["ig_id"],
          index: index,
          like_count: post["like_count"],
          comments_count: post["comments_count"]
        )
        Database.database[:posts].insert(new_entry)
        entries_to_post_to_telegram << new_entry
      end

      begin
        telegram_media_entries = entries_to_post_to_telegram.collect do |entry|
          sleep(3) # Telegram does some annoying rate limiting
          Telegram::Bot::Types::InputMediaPhoto.new(
            media: entry[:signed_url], # Telegram can easily access URLs directly
            type: entry[:is_video] ? "video" : "photo",
          ) 
        end.compact
        sleep(10)
        if telegram_media_entries.count > 0 && !ENV["SKIP_TELEGRAM_FOR_POSTS"]
          telegram_media_entries[0][:caption] = base_entry[:caption] # as per https://stackoverflow.com/questions/58893142/how-to-send-telegram-mediagroup-with-caption-text
          puts "Uploading new post to Telegram"
          self.telegram_client.api.send_media_group(
            chat_id: telegram_chat_id,
            media: telegram_media_entries,
          )
        end
      rescue => ex
        # Now delete the db entries again
        Database.database[:posts].where(ig_id: base_entry[:ig_id]).delete
        puts ex.message
        puts ex.backtrace.join("\n")
        # Send message to Telegram
        self.telegram_client.api.send_message(
          chat_id: telegram_chat_id,
          text: "Instagram API error, please investigate"
        )
      end
    end

    def download_and_store_asset(ig_id:, file_name_to_use:, media_url:, expires:, prefix_folder:)
      file_path = File.join("/tmp/", ig_id)
      File.write(file_path, URI.open(media_url).read)

      extension = file_type(file_path) == :video ? ".mp4" : ".jpg"
      output_path = File.join(user_id, "#{prefix_folder}/#{file_name_to_use}#{extension}")
      puts "uploading file to Google Cloud #{output_path}"
      created_file = Database.file_storage_bucket.create_file(file_path, output_path)

      return {
        file_path: file_path,
        signed_url: created_file.signed_url(method: "GET", expires: expires),
        output_path: output_path
      }
    rescue => ex
      puts ex
      return nil
    end

    # Detect if it's a video or photo that was posted
    def file_type(file_path)
      file_type = Marcel::MimeType.for(Pathname.new(file_path))

      if file_type.include?("image/jpeg")
        return :photo
      elsif file_type.include?("video/mp4")
        return :video
      else
        puts "Unknown file type #{file_type}"
        binding.pry
      end
    end
  end
end

def refresh_stories_and_posts
  Database.database[:facebook_access_tokens].each do |fb_token|
    instagram = Instapipe::Instagram.new(fb_token_entry: fb_token)
    matching_telegram_groups = Database.database[:telegram_chat_ids].where(user_id: fb_token[:user_id])
    instagram.stories(telegram_chat_id: (matching_telegram_groups.first[:telegram_chat_id] rescue nil))
    instagram.posts(telegram_chat_id: (matching_telegram_groups.first[:telegram_chat_id] rescue nil))
  rescue => ex
    puts fb_token
    puts ex.message
    puts ex.backtrace.join("\n")
  end
end

if __FILE__ == $0
  refresh_stories_and_posts
end
