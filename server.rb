require 'sinatra'
require_relative "./database"
require_relative "./facebook_token"

set :bind, '0.0.0.0'
set :port, ENV.fetch("PORT")
set :environment, :production unless ENV["DEVELOPMENT"] == true

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
  active_stories = Database.database[:stories].where(user_id: @krausefx_user_id).find_all do |story|
    relative_diff_in_seconds = (Time.now - Time.at(story[:timestamp]))
    relative_diff_in_h = relative_diff_in_seconds / 60 / 60
    relative_diff_in_h <= 24 # only show the most recent stories
  end
  @stories_available = active_stories.count > 0
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
  Database.database[:stories].where(user_id: user_id).each do |story|
    relative_diff_in_seconds = (Time.now - Time.at(story[:timestamp]))
    relative_diff_in_h = relative_diff_in_seconds / 60 / 60
    next if relative_diff_in_h > 24 # only show the most recent stories

    formatted_time_diff = time_diff(relative_diff_in_seconds)

    output << {
      signed_url: story[:signed_url],
      timestamp: story[:timestamp],
      is_video: story[:is_video],
      caption: story[:caption],
      permalink: story[:permalink],
      relative_diff_in_h: relative_diff_in_h,
      formatted_time_diff: formatted_time_diff,
      user_id: user_id,
    }
  end

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
  user_id = params.fetch(:user_id)

  all_posts_ig_ids = Database.database[:posts].where(user_id: user_id).order_by(:ig_id).to_a.collect { |a| a[:ig_id] }.uniq

  output = all_posts_ig_ids.collect do |ig_id|
    all_media_items = Database.database[:posts].where(user_id: user_id, ig_id: ig_id)
    post = all_media_items.first
    relative_diff_in_seconds = (Time.now - Time.at(post[:timestamp]))
    relative_diff_in_h = relative_diff_in_seconds / 60 / 60

    formatted_time_diff = time_diff(relative_diff_in_seconds)    

    {
      relative_diff_in_h: relative_diff_in_h,
      formatted_time_diff: formatted_time_diff,
      timestamp: post[:timestamp],
      caption: post[:caption],
      permalink: post[:permalink],
      user_id: user_id,
      media: all_media_items.sort_by { |a| a[:index] }.collect do |media_item| # TODO: sort by index
        {
          signed_url: media_item[:signed_url],
          is_video: media_item[:is_video],
          index: media_item[:index]
        }
      end
    }
  end.sort_by { |a| a[:timestamp] }.reverse

  headers('Access-Control-Allow-Origin' => "*")
  content_type('application/json')

  output.to_json
end

get "/didOpenStories" do
  date = Date.today
  user_id = params.fetch(:user_id)

  headers('Access-Control-Allow-Origin' => "*")

  existing_entry = Database.database[:views].where(date: date, user_id: user_id)
  existing_entry.update(count: existing_entry.first[:count] + 1)

  "Success"
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
