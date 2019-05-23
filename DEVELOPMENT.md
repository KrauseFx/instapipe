# Development

## Dependencies

```
bundle install
```

## Backend

```
bundle exec ruby server.rb
```

## Scheduler

```
bundle exec rake telegram
```

## Environment variables

```
export TELEGRAM_TOKEN=""
export TELEGRAM_CHAT_ID=""

# The Instagram session ID
export SESSIONID=""
export DS_USER_ID=""
export USER_TO_WATCH="4409072"
export DATABASE_URL="postgresql://felixkrause@localhost/instapipe"

export GC_PROJECT_ID=""
export GC_BUCKET_NAME=""
export GC_KEYS=""
```

`GC_KEYS` can either be an environment variable, or you can pass the Google Cloud credentials by having a `gc_keys.json` file in the root directory of the project
