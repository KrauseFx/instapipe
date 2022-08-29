require_relative "./instagram.rb"
puts "Starting cronjob"

loop do
  refresh_stories
  sleep(60 * 60) # sleep for 1 hour
end
