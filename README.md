# instapipe

Built by [Felix Krause](https://twitter.com/KrauseFx)

README will follow

For now, see it in action: 

- [Plain live demo](https://krausefx.github.io/instapipe/web/index.html)
- [Integrated into krausefx.com](https://krausefx.com)
- API Access: [instapipe.herokuapp.com/stories.json](https://instapipe.herokuapp.com/stories.json)

This is used on [whereisfelix.today](https://whereisfelix.today) and [krausefx.com](https://krausefx.com), as well as to send stories to my friends who don't use Instagram every day (good for them), via Telegram.

All messages are automatically being piped over a Telegram channel, stored on Google Cloud Storage, and the metadata in a Postgres database.

After all, the stories you post are **your content** and should be available via an open API. Instagram fullfills the GDPR requirements by providing a manual export feature, but they won't allow you to get real-time access to your own data.
