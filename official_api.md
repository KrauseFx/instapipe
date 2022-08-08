- How to setup to cross-share on FB personal account still

curl -i -X GET \
 "https://graph.facebook.com/v14.0/17841401712160068/media?fields=caption%2Cmedia_url&access_token=EAAfQ6YOSLasBAIBPZCwoOuvuAQLzAvZAg7aYgiKOoALXxJFkZAWTwlKOA8iBXB24gMlNNBS1O9oaAbykCJvseYu3CxbXr7SfmcDpjcIZBdx9FpW3JYBxlA69IOguajDblhzE698OaZBq0nC25E4JmBRlR6AQcMrd7C6w2BTlpYKlHNDM3CpZBdOq4bWHeINECYtsy93ZCuMMZBOPwZA3JNXZCL6IqNC0JZAfuHZC62uUoVKfTzSTFR1wLcB7"

 ```json
 {
  "data": [
    {
      "caption": "Tomorrowland 2022, it’s a wrap 🎁 
3 days - 60,000 steps - lost 2kg - saw some of my favorite artists, most notable @ericprydz @borisbrejcha @artbatmusic @lostfrequencies @iampaulkalkbrenner, and so many new ones 🕺💃 it’s hard to comprehend the sheer size of it all, so many beautifully designed stages, the whole park turned into a Disney Land

Thank you @sportg33k and @andygutcia for the last minute tickets, all the planning happened within 2 weeks",
      "media_url": "https://scontent-vie1-1.cdninstagram.com/v/t51.29350-15/296793816_755031642428904_1648176469200029992_n.jpg?_nc_cat=104&ccb=1-7&_nc_sid=8ae9d6&_nc_ohc=poY8GVqz5qcAX_1i52A&_nc_ht=scontent-vie1-1.cdninstagram.com&edm=AM6HXa8EAAAA&oh=00_AT9WaG2mXkqM6hEPhUop2708azGJ0DD6-FP-nveCYAWM9g&oe=62F581AE",
      "id": "17929786562388112"
    },
    {
      "caption": "Thanks For Coming To My TED Talk 🎤 
One big bucket list item complete aaaand finally getting the right to use that meme line IRL 😎

It was an honor sharing my ideas and vision of howIsFelix.today at @tedxiemadrid earlier this year and being part of this amazing event!

Just received the photos for now, the official recording will be available soon on a ted.com website near you! 

Thanks for the invitation @gayle_were @merchysalce and the rest of the crew. Photos by @not_gold_but",
      "media_url": "https://scontent-vie1-1.cdninstagram.com/v/t51.29350-15/295182432_591853819284817_265412634156808072_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=8ae9d6&_nc_ohc=1b4CqpwQKXMAX9fgYm-&_nc_ht=scontent-vie1-1.cdninstagram.com&edm=AM6HXa8EAAAA&oh=00_AT9_j2y-Sg7t0WErKYFlIRwu1c8CO9glVJbpBdo_tLsJmA&oe=62F5B11E",
      "id": "18303794995054925"
    },
    {
      "caption": "Weekend in Barcelona to celebrate @flxwind’s graduation: walking 30,000 steps during the day, 6am drone flights on the rooftop, 7am hotel breakfast buffet, super blocks and Bling Bling at night 🕺🇪🇸 also got to know about the secret Titans group of people above 1.97m 🤫",

```

## instapipe.net 2.0

```
curl -i -X GET \
 "https://graph.facebook.com/v14.0/17841401712160068/stories?fields=caption%2Cmedia_product_type%2Cmedia_url%2Clike_count%2Cthumbnail_url%2Ctimestamp%2Cusername%2Cchildren%2Cpermalink&access_token=EAAfQ6YOSLasBAFCrL2ROCmZCXZCDPn5DdXjq4OoNloXbU9iAN4oczl9SEuCZCfA6zsZAma7lRtxOb9wZAcDoR85V9tw5IYY7TjMYxugIxNqDPh0jAVl9wBdaZA9thPN09mZAi3BV55Gl6bazooU74PRqUSjPHEsEOPpGDVFkauAwVxWZB07xpZBeMrfZCJCKMZCk0tvc835ZCKEhtAZDZD"
 ```

```json
{
  "data": [
    {
      "media_product_type": "STORY",
      "media_url": "https://scontent-vie1-1.cdninstagram.com/v/t51.29350-15/297875408_110000911729156_3687912783050751305_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=8ae9d6&_nc_ohc=DvpEoshjezUAX-GSuHQ&_nc_ht=scontent-vie1-1.cdninstagram.com&edm=AB9oSrcEAAAA&oh=00_AT_lpAK2o2twcogkCwx7xVHeEjh8k-khdQomLj1BxNIGTQ&oe=62F6D876",
      "like_count": 0,
      "timestamp": "2022-08-08T21:16:14+0000",
      "username": "krausefx",
      "permalink": "https://instagram.com/stories/krausefx/2900557134627408873",
      "id": "17934267341219985"
    }
  ],
  "paging": {
    "cursors": {
      "before": "QVFIUnlqeWhvQmU5Vnl5WnFJdENuOWFiV3VCLUVxOC1nX25NTVlobEJlVGp2ZAGZA2bXl3NE1yVmFRdVhjUmlBV3RWT0dDd1g4a1FIZAHNwakxfMG4xcVhpdUdB",
      "after": "QVFIUnlqeWhvQmU5Vnl5WnFJdENuOWFiV3VCLUVxOC1nX25NTVlobEJlVGp2ZAGZA2bXl3NE1yVmFRdVhjUmlBV3RWT0dDd1g4a1FIZAHNwakxfMG4xcVhpdUdB"
    }
  }
}
```


