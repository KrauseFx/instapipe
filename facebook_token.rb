require_relative "./database"
require "net/https"

module Instapipe
  class FacebookToken
    attr_accessor :user_id

    # user_id: that's the business user id
    # https://developers.facebook.com/docs/instagram-api/getting-started/
    def initialize(user_id: nil)
      @user_id = user_id
    end

    def short_access_token
      Database.database[:facebook_access_tokens].where(user_id: user_id).first[:user_access_token_used]
    end

    def generate_long_lived_access_token
      existing_tokens = Database.database[:facebook_access_tokens].where(user_id: user_id)
      if existing_tokens.count > 0
        existing_token = existing_tokens.first
        if existing_token[:expires_at].nil?
          # This is the first time getting the long term token
        elsif existing_token[:expires_at] > Time.now
          return existing_token[:long_lived_access_token]
        else
          puts "Existing token expired, trying to generate a new one"
          # TODO: I think this won't work. Instead we'll need to text the user to go through the flow again
          Database.database[:facebook_access_tokens].where(user_id: user_id).delete
        end
      end

      uri = URI("https://graph.facebook.com/v14.0/oauth/access_token")
      uri.query = URI.encode_www_form( 
        grant_type: "fb_exchange_token",
        client_id: ENV.fetch("INSTAGRAM_APP_ID"),
        client_secret: ENV.fetch("INSTAGRAM_APP_SECRET"),
        fb_exchange_token: short_access_token
      )
      res = Net::HTTP.get_response(uri)
      parsed = JSON.parse(res.body)
      if parsed["access_token"]
        Database.database[:facebook_access_tokens].where(user_id: user_id).update({
          long_lived_access_token: parsed["access_token"],
          expires_at: (Time.now + parsed["expires_in"].to_i)
        })
        return parsed["access_token"]
      else
        raise "Could not fetch access token: #{parsed}"
      end
    end

    def new_login_flow(code:)
      # Now use the token to get an access token
      url = URI("https://graph.facebook.com/v14.0/oauth/access_token")
      url.query = URI.encode_www_form(
        client_id: ENV.fetch("INSTAGRAM_APP_ID"),
        redirect_uri: REDIRECT_URI,
        client_secret: ENV.fetch("INSTAGRAM_APP_SECRET"),
        code: code
      )

      res = Net::HTTP.get_response(url)
      parsed = JSON.parse(res.body)
      if parsed["access_token"]
        access_token = parsed["access_token"]
        # Use the token to get the User ID so we can store it in the db
        url = URI("https://graph.facebook.com/v14.0/me/accounts")
        url.query = URI.encode_www_form(access_token: access_token)
        res = JSON.parse(Net::HTTP.get_response(url).body)
        stories_app = res["data"].find { |app| app["name"] == "Krausefxstories" }
        stories_app_access_token = stories_app["access_token"]
        stories_app_id = stories_app["id"]

        # Use the pages' token to get the Instagram Business User ID
        url = URI("https://graph.facebook.com/v14.0/#{stories_app_id}")
        url.query = URI.encode_www_form(fields: "instagram_business_account", access_token: stories_app_access_token)
        res = JSON.parse(Net::HTTP.get_response(url).body)
        @user_id = res["instagram_business_account"].fetch("id")
        puts "Found business user id #{@user_id}"

        # Check if we have an existing entry, if so we need to update that one
        if Database.database[:facebook_access_tokens].where(user_id: @user_id).count > 0
          puts "we've had a token before, but we will update it"
          Database.database[:facebook_access_tokens].where(user_id: @user_id).update({
            user_access_token_used: access_token,
            long_lived_access_token: nil,
            expires_at: nil
          })
        else
          puts "A new user"
          Database.database[:facebook_access_tokens].insert({
            user_id: @user_id,
            user_access_token_used: access_token,
            long_lived_access_token: nil
          })
        end
        self.generate_long_lived_access_token
      else
        raise "No access token: #{parsed}"
      end
    rescue => ex
      puts ex.message
      puts ex.backtrace.join("\n")
      raise ex
    end
  end
end
