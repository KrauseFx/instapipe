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
bundle exec ruby scheduler.rb
```

## Environment variables

```
GC_BUCKET_NAME
GC_KEYS
GC_PROJECT_ID
IG_BUSINESS_USER_ID
INSTAGRAM_APP_ID
INSTAGRAM_APP_SECRET
INSTAGRAM_USER_ACCESS_TOKEN
KRAUSEFX_USER_FOR_DEMO
TELEGRAM_TOKEN
DATABASE_URL
```


To get the `TELEGRAM_CHAT_ID`, use Telegram Web, open the Group, and look at the address bar, find something like `-1647951758`, and prefix it with `-100` (https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id/69302407#69302407)

`GC_KEYS` can either be an environment variable, or you can pass the Google Cloud credentials by having a `gc_keys.json` file in the root directory of the project

## Generating the widget

```
bundle exec ruby generate_widget.rb
```

This will generate `instapipe.html`, a single file containing all the "dependencies" needed
