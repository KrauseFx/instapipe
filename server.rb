require 'sinatra'
require_relative "./database"

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

get '/stories.json' do
  output = []
  user_id = params[:user_id]
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
  existing_entry = Database.database[:views].where(date: date)
  if existing_entry.count == 0
    Database.database[:views].insert({
      date: date,
      count: 0,
      prefetches: 0
    })
    existing_entry = Database.database[:views].where(date: date)
  end

  existing_entry.update(
    count: existing_entry.first[:count],
    prefetches: existing_entry.first[:prefetches] + 1
  )

  headers('Access-Control-Allow-Origin' => "*")
  content_type('application/json')

  output.to_json
end

get "/didOpenStories" do
  date = Date.today

  headers('Access-Control-Allow-Origin' => "*")

  existing_entry = Database.database[:views].where(date: date)
  existing_entry.update(count: existing_entry.first[:count] + 1)

  "Success"
end

# To be used for e.g. Messenger bot clients
# Open standards are such a beautiful thing, am I right!?
get '/feed.xml', provides: ['rss'] do
  require 'rss'

  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.author = "@KrauseFx"
    maker.channel.updated = Time.now.to_s
    maker.channel.about = "Stories of KrauseFx"
    maker.channel.title = "Stories of KrauseFx"

    Database.database[:stories].each do |story|
      maker.items.new_item do |item|
        item.link = story[:signed_url]
        item.title = "New Story"
        item.updated = Time.now.to_s
      end
    end
  end

  rss.to_xml
end
