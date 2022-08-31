require 'sinatra'
require_relative "./database"
require_relative "./facebook_token"

set :bind, '0.0.0.0'
set :port, ENV.fetch("PORT")
set :environment, :production unless ENV["DEVELOPMENT"].to_s.length > 0

REDIRECT_URI = "https://instapipe.net/fb/auth"

get '/' do
  # Render login page
  @login_url = URI("https://www.facebook.com/v14.0/dialog/oauth")
  @login_url.query = URI.encode_www_form(
    client_id: ENV.fetch("INSTAGRAM_APP_ID"),
    redirect_uri: REDIRECT_URI,
    state: "instapipe"
  )

  @login_url = @login_url.to_s
  @krausefx_user_id = ENV.fetch("KRAUSEFX_USER_FOR_DEMO")
  @posts = posts_json(@krausefx_user_id)

  erb :index
end

get "/fb/auth" do
  puts "Got auth code /fb/auth"
  code = params.fetch("code")

  fb_token = Instapipe::FacebookToken.new
  fb_token.new_login_flow(code: code)

  # Render success page
  return "Success, from now on we will follow your stories"
end

get '/stories.json' do
  output = []
  user_id = params.fetch(:user_id)
  
  output = stories_json(user_id)

  date = Date.today
  existing_entry = Database.database[:views].where(date: date, user_id: user_id)
  if existing_entry.count == 0
    Database.database[:views].insert({
      date: date,
      count: 0,
      prefetches: 0,
      user_id: user_id
    })
    existing_entry = Database.database[:views].where(date: date, user_id: user_id)
  end

  existing_entry.update(
    count: existing_entry.first[:count],
    prefetches: existing_entry.first[:prefetches] + 1
  )

  headers('Access-Control-Allow-Origin' => "*")
  content_type('application/json')

  output.to_json
end

get '/posts.json' do
  headers('Access-Control-Allow-Origin' => "*")
  content_type('application/json')

  posts_json(params.fetch(:user_id)).to_json
end

get "/didOpenStories" do
  date = Date.today
  user_id = params.fetch(:user_id)

  headers('Access-Control-Allow-Origin' => "*")

  existing_entry = Database.database[:views].where(date: date, user_id: user_id)
  existing_entry.update(count: existing_entry.first[:count] + 1)

  "Success"
end

get '/assets/*' do
  if [
    "/assets/apiScreenshot.jpg",
    "/assets/databaseScreenshot.jpg",
    "/assets/howisfelixScreenshot.jpg",
    "/assets/telegramScreenshot.jpg",
  ].include?(request.path)
    return send_file(File.join(".", request.path))
  else
    return nil
  end
end

# Helpers

def stories_json(user_id)
  return Database.database[:stories].where(user_id: user_id).collect do |story|
    relative_diff_in_seconds = (Time.now - Time.at(story[:timestamp]))
    relative_diff_in_h = relative_diff_in_seconds / 60 / 60
    next if relative_diff_in_h > 24 # only show the most recent stories

    formatted_time_diff = time_diff(relative_diff_in_seconds)

    {
      signed_url: story[:signed_url],
      timestamp: story[:timestamp],
      is_video: story[:is_video],
      caption: story[:caption],
      permalink: story[:permalink],
      relative_diff_in_h: relative_diff_in_h,
      formatted_time_diff: formatted_time_diff,
      user_id: user_id,
    }
  end.compact
end

def posts_json(user_id)
  all_posts = Database.database[:posts].where(user_id: user_id).order_by(:timestamp).reverse.to_a
  all_posts_ig_ids = all_posts.collect { |a| a[:ig_id] }.uniq

  return all_posts_ig_ids.collect do |ig_id|
    all_media_items = all_posts.find_all { |a| a[:ig_id] == ig_id }.sort_by { |a| a[:index] }
    post = all_media_items.first
    relative_diff_in_seconds = (Time.now - Time.at(post[:timestamp]))
    relative_diff_in_h = relative_diff_in_seconds / 60 / 60

    formatted_time_diff = time_diff(relative_diff_in_seconds)    
    thumbnail_url = all_media_items.find_all do |media_item|
      media_item[:is_video] == false
    end.first.fetch(:signed_url, nil)

    {
      relative_diff_in_h: relative_diff_in_h,
      formatted_time_diff: formatted_time_diff,
      timestamp: post[:timestamp],
      caption: post[:caption],
      permalink: post[:permalink],
      user_id: user_id,
      thumbnail_url: thumbnail_url,
      ig_id: ig_id,
      media: all_media_items.collect do |media_item|
        {
          signed_url: media_item[:signed_url],
          is_video: media_item[:is_video],
          index: media_item[:index],
          ig_id: media_item[:ig_id]
        }
      end
    }
  end.sort_by { |a| a[:timestamp] }.reverse
end

def time_diff(seconds_diff)
  seconds_diff = seconds_diff.to_i

  hours = seconds_diff / 3600
  seconds_diff -= hours * 3600

  minutes = seconds_diff / 60
  seconds_diff -= minutes * 60

  if hours > 0
    return "#{hours}h"
  elsif minutes > 20
    return "#{minutes}m"
  else
    return "Just now"
  end
end
