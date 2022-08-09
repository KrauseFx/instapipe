# Use this file to easily define all of your cron jobs.
#

set :output, "/tmp/cron_log.log"
every 5.minutes do # TODO: Every hour
  rake "telegram"
end
