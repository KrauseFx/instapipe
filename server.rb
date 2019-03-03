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
      location: JSON.parse(story[:location])
    }
  end
  output.to_json
end