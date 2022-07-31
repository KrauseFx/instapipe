require_relative "./instapipe"

task :telegram do
  instapipe = Instapipe::Instapipe.new(sessionid: ENV["SESSIONID"], ds_user_id: ENV["DS_USER_ID"])

  instapipe.stories(
    user_id: ENV["USER_TO_WATCH"],
    chat_id: ENV["TELEGRAM_CHAT_ID"]
  )
end

task :telegram_grosser_felix do
  instapipe = Instapipe::Instapipe.new(sessionid: ENV["SESSIONID"], ds_user_id: ENV["DS_USER_ID"])

  instapipe.stories(
    user_id: ENV["USER_TO_WATCH_2"],
    chat_id: ENV["TELEGRAM_CHAT_ID_2"]
  )
end
