require 'sinatra'
require_relative "./database"

get '/stories.json' do
  output = []
  Database.database[:stories].each do |story|
    relative_diff_in_h = (Time.now - Time.at(story[:timestamp]))/60/60
    next if relative_diff_in_h > 24 # only show the most recent stories

    output << {
      signed_url: story[:signed_url],
      timestamp: story[:timestamp],
      is_video: story[:is_video],
      height: story[:height],
      width: story[:width],
      relative_diff_in_h: relative_diff_in_h,
      location: JSON.parse(story[:location] || "{}")
    }
  end

  headers('Access-Control-Allow-Origin' => "*")
  content_type('application/json')

  output.to_json
end

get "/didOpenStories" do
  date = Date.today
  existing_entry = Database.database[:views].where(date: date)

  if existing_entry.count == 0
    Database.database[:views].insert({
      date: Date.today,
      count: 0
    })
    existing_entry = Database.database[:views].where(date: date)
  end

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
