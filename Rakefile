require_relative "./instapipe"

task :telegram do
  instapipe = Instapipe::Instapipe.new(sessionid: ENV["SESSIONID"], ds_user_id: ENV["DS_USER_ID"])
  instapipe.stories(user_id: ENV["USER_TO_WATCH"])
end
