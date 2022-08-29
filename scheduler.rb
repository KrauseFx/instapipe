# Use this file to easily define all of your cron jobs.
#
require_relative "./instagram.rb"
puts "Starting cronjob"

loop do
  refresh_stories
  sleep(60 * 60) # sleep for 1 hour
end
