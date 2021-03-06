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
# Telegram
export TELEGRAM_TOKEN=""
export TELEGRAM_CHAT_ID=""

# The Instagram session ID
export SESSIONID=""
export DS_USER_ID=""
export USER_TO_WATCH="4409072"


# Others
export DATABASE_URL="postgresql://felixkrause@localhost/instapipe"
export GC_PROJECT_ID=""
export GC_BUCKET_NAME=""
export GC_KEYS=""
```

`GC_KEYS` can either be an environment variable, or you can pass the Google Cloud credentials by having a `gc_keys.json` file in the root directory of the project

### Instagram keys

I use a "bot" account for the session, to ensure my main Instagram account doesn't get blocked, as this account is probably against the terms of services (just like the lack of real-time API is against GDPR IMO). Use at your own risk

To get the Instagram specific environment variables, access instagram.com with your secondary account, and use a man-in-the-middle proxy like Charles or Proxyman to fetch the cookies (or your browser), look for the

- `ds_user_id`
- `sessionid`

## Generating the widget

```
bundle exec ruby generate_widget.rb
```

This will generate `instapipe.html`, a single file containing all the "dependencies" needed
