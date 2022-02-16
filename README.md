<h1 style="text-align: center;">instapipe.net</h1>



<div id="story-available" class="story-not-available">
  <img 
    src="https://krausefx.com/assets/FelixKrauseCropped.jpg"
    id="storyProfilePicture"
    onclick="showStories()"
  />
</div>

<div id="storyViewer">
  <div id="storyViewerDimmedBackground" onclick="dismissStories()"></div>
  <div id="storyContent">
    <div id="storyHeader">
      <img 
        id="storyHeaderProfilePicture"
        onclick="window.open('https://instagram.com/krausefx', '_blank')"
      />
      <p id="storyUserlink"><a href="https://instagram.com/krausefx" target="_blank">KrauseFx</a></p>
      <p id="storyTimestamp"></p>
      <p id="poweredByInstapipe"><a href="https://instapipe.net" target="_blank">instapipe.net</a></p>
    </div>
    <div id="storyProgressBar"></div>
    <div id="storyBackButton" class="storyButton" onclick="userDidClickPreviousStory()">
      &#x3C;
    </div>
    <div id="storyNextButton" class="storyButton" onclick="userDidClickNextStory()">
      &#x3E; 
    </div>

    <video autoplay playsinline muted id="storyVideoViewer">
    </video>
    <div id="storyPhotoViewer" onclick="userDidClickNextStory()">
    </div>
  </div>
  <img src="" id="fakeContentToPreloadImages" />
</div>

<script type='text/javascript'>
let host = "https://instapipe.herokuapp.com/"
let userId = "4409072"

var storiesToShow = null;
var timeOutForPhotos = 4.0;
var storyProgressSpacing = 5;
var progressPadding = 2;
var progressBars = null;
var storiesContent = null;

var nextStoryTimeout = null;
var currentIndex = -1;

function preloadStoriesIndex() {
  var url = host + "stories.json?user_id=" + userId;

  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() { 
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      storiesContent = JSON.parse(xmlHttp.responseText)
      if (storiesContent.length > 0) {
        document.getElementById("story-available").classList.remove("story-not-available");

        // preload the first story if it's a picture
        if (!storiesContent[0]["is_video"]) {
          document.getElementById("fakeContentToPreloadImages").src = storiesContent[0]["signed_url"]
        }
      }
    }
  };

  xmlHttp.open("GET", url, true); // true = asynchronous 
  xmlHttp.send(null);
}

function showStories() {
  if (storiesContent == null || storiesContent.length == 0) {
    return;
  }

  // Copy the profile picture URL to the story header, to only have to define it once
  // we only do that once everything is loaded, as depending on the website
  // the image node might not be acccessible yet
  let profileImageURL = document.getElementById("storyProfilePicture").src
  document.getElementById("storyHeaderProfilePicture").src = profileImageURL;

  storiesToShow = []
  progressBars = []

  document.getElementById("storyViewer").style.display = "block"

  for (let storyIndex in storiesContent) {
    let currentStory = storiesContent[storyIndex]
    storiesToShow.push(currentStory)
  }

  for (let currentStoryIndex in storiesToShow) {
    let currentStory = storiesToShow[currentStoryIndex]

    // Append the progress items
    var progressBarBackground = document.createElement("div")
    progressBarBackground.className = "storyProgressBarItemBg"
    progressBarBackground.style.width = "calc(" + (1.0 / storiesToShow.length) * 100 + "%" + " - " + progressPadding * 2 + "px)"
    progressBarBackground.style.marginRight = progressPadding + "px"
    progressBarBackground.style.marginLeft = progressPadding + "px"
    document.getElementById("storyProgressBar").appendChild(progressBarBackground)

    var progressBarForeground = document.createElement("div")
    progressBarForeground.style.width = "0%"
    progressBarForeground.className = "storyProgressBarItemFg"
    progressBarBackground.appendChild(progressBarForeground)

    progressBars.push(progressBarForeground)
  }

  currentIndex = 0
  renderCurrentStory()

  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {}
  xmlHttp.open("GET", host + "didOpenStories", true); // true = asynchronous 
  xmlHttp.send(null);
}

function renderCurrentStory() {
  currentStory = storiesToShow[currentIndex]
  
  for (let index in progressBars) {
    let currentProgressBar = progressBars[index]
    if (currentIndex > index) {
      currentProgressBar.style.width = "100%"
    } else {
      currentProgressBar.style.width = "0%"
    }
  }

  // Show image/video
  let videoViewer = document.getElementById("storyVideoViewer")
  let photoViewer = document.getElementById("storyPhotoViewer")
  let progressBarContent = progressBars[currentIndex]

  document.getElementById("storyTimestamp").textContent = currentStory["formatted_time_diff"]

  if (currentStory["is_video"]) {
    videoViewer.src = currentStory["signed_url"]
    videoViewer.style.display = "block"
    videoViewer.onended = function() {
      if (currentIndex < storiesToShow.length - 1) {
        currentIndex++;
        renderCurrentStory();
      } else {
        dismissStories();
      }
    };
    let videoUpdatedDuration = function() {
      // this is triggered when the video file was loaded
      // videos have dynamic length
      animateProgressBar(progressBarContent, videoViewer.duration)
      videoViewer.removeEventListener("durationchange", videoUpdatedDuration)
    }
    videoViewer.addEventListener("durationchange", videoUpdatedDuration)
    videoViewer.load()
    videoViewer.play()
    photoViewer.style.display = "none"
  } else {
    photoViewer.style.backgroundImage = "url('" + currentStory["signed_url"] + "')"
    videoViewer.style.display = "none"
    photoViewer.style.display = "block"
    animateProgressBar(progressBarContent, timeOutForPhotos) // photos are always x seconds

    // Advance to next story after X seconds
    nextStoryTimeout = setTimeout(function() {
      if (currentIndex < storiesToShow.length - 1) {
        currentIndex++;
        renderCurrentStory();
      } else {
        dismissStories();
      }
    }, timeOutForPhotos * 1000)
  }

  // Trigger the next one
  if (currentIndex < storiesToShow.length - 1 && !storiesToShow[currentIndex + 1]["is_video"])
  {
    setTimeout(function() {
      // Poor person's pre-loading of images, with a slight delay
      document.getElementById("fakeContentToPreloadImages").src = storiesToShow[currentIndex + 1]["signed_url"]
    }, timeOutForPhotos / 3.0 * 1000)
  }
}

function animateProgressBar(progressBar, duration) {
  progressBar.style.animationName = "storyViewProgress";
  progressBar.style.animationDuration = duration + "s";
}

function userDidClickPreviousStory() {
  if (currentIndex > 0) {
    stopAllAnimations()
    currentIndex--;
    renderCurrentStory();
  } else {
    dismissStories();
  }
}

function userDidClickNextStory() {
  if (currentIndex < storiesToShow.length - 1) {
    stopAllAnimations()
    currentIndex++;
    renderCurrentStory();
  } else {
    dismissStories();
  }
}

function stopAllAnimations() {
  clearTimeout(nextStoryTimeout)
  document.getElementById("storyVideoViewer").onended = null

  for (let index in progressBars) {
    let currentProgressBar = progressBars[index]
    currentProgressBar.style.animationName = null
  }
}

function dismissStories() {
  document.getElementById("storyViewer").style.display = "none"
  document.getElementById("storyProgressBar").innerHTML = ""
  stopAllAnimations()
}

window.addEventListener("keyup", function(e) {
  if (e.keyCode == 27) { // ESC
    dismissStories()
    return true;
  }
  if (e.keyCode == 37) { // Left
    userDidClickPreviousStory();
  }
  if (e.keyCode == 39) { // Right
    userDidClickNextStory();
  }
}, false);

preloadStoriesIndex();

</script>
<style type='text/css'>
#storyProfilePicture {
  width: 128px;
  height: 128px;
  border-radius: 70px;
  margin-left: 3px;
  margin-top: 3px;
  cursor: pointer;
  border: 4px solid white;
}

#story-available {
  background-image: linear-gradient(rgb(186, 62, 138), #fba051);
  height: 142px;
  width: 142px;
  z-index: -10;
  border-radius: 70px;
  margin-bottom: 15px;
}

#story-available.story-not-available {
  background-image: none !important;
}

#storyViewer {
  height: 100%;
  width: 100%;
  position: fixed;
  top: 0;
  left: 0;
  z-index: 100;
  text-align: center;
  display: none;

  font-family: 'Helvetica Neue', sans-serif;
  font-weight: normal;
}
#storyViewer > #storyViewerDimmedBackground {
  /* This is a separate div to allow onclick events */
  background-color: rgba(0, 0, 0, 0.8);
  height: 100%;
  width: 100%;
  z-index: -1;
  position: absolute;
}

#storyViewer p {
  color: #686868;
  font-size: 20px;
  line-height: 24px;
  margin: 0 0 24px;
  text-align: center;
  text-justify: inter-word;
}

#storyViewer > #storyContent {
  width: 512px;
  max-width: 80%; /* for mobile devices */
  margin-top: 30px;
  display: inline-block;

  /* 
    To get the right aspect ratio, while still having a dynamic content size
    https://stackoverflow.com/questions/1495407/maintain-the-aspect-ratio-of-a-div-with-css
    IG content: 910px height to 512px width = ~178%
    So the `padding-bottom` sets the height of the content
  */
  padding-bottom: 178%;
}

#storyViewer > #storyContent > .storyButton {
  position: fixed;
  top: calc(910px - 450px);
  background-color: rgba(200, 200, 200, 0.88);
  padding: 10px;
  color: rgba(0, 0, 0, 0.8);
  font-weight: bolder;
  font-size: 16px;
  border-radius: 18px;
  width: 20px;
  height: 20px;
  text-align: center;
  cursor: pointer;
}

#storyViewer > #storyContent > #storyBackButton {
  left: 50px;
}

#storyViewer > #storyContent > #storyNextButton {
  right: 53px; /* no idea where the difference comes from */
}

#storyViewer > #storyContent > #storyPhotoViewer {
  width: 100%;
  padding-bottom: 178%; /* see comment in #storyContent */
  background-size: cover;
  background-repeat: no-repeat;
  background-position: 50% 50%;
}

#storyViewer > #storyContent > #storyVideoViewer {
  padding-bottom: 178%; /* see comment in #storyContent */
  width: 100%;
}

#storyViewer > #storyContent > #storyProgressBar {
  width: calc(100% + 4px);
  margin-left: -2px;
  height: 3px;
  margin-top: 10px;
  margin-bottom: 10px;
}

#storyViewer > #storyContent > #storyProgressBar > .storyProgressBarItemBg {
  border-radius: 6px;
  background-color: rgba(187, 187, 187, 0.6);
  height: 100%;
  display: inline-block;
  float: left;
}

.storyProgressBarItemFg {
  background-color: #FFF;
  height: 100%;
  border-radius: 3px;
  animation-timing-function: linear;
}

#fakeContentToPreloadImages {
  height: 0;
  width: 0;
  opacity: 0;
}

@keyframes storyViewProgress {
  from { width: 0%; }
  to { width: 100%; }
}

/* Story header */
#storyHeader {
  height: 50px;
  text-align: left;
}

#storyHeader > #storyHeaderProfilePicture {
  height: 38px;
  width: 38px;
  border-radius: 19px;
  cursor: pointer;
  margin-top: 7px;
  display: block-inline;
}

#storyHeader > #storyUserlink {
  display: block-inline;
  margin-left: 50px;
  text-align: left;
  margin-top: -40px; /* hacky */
  padding-top: 0;
  font-size: 20px;
}

#storyHeader > #storyUserlink > a {
  color: white !important;
  text-decoration: none;
}

#storyHeader > #storyTimestamp {
  color: #777;
  display: block-inline;
  margin-left: 50px;
  text-align: left;
  margin-top: -28px;
  padding-top: 0;
  font-size: 16px;
}

#storyHeader > #poweredByInstapipe {
  display: block-inline;
  margin-left: 150px;
  text-align: right;
  margin-top: -50px; /* hacky */
  padding-top: 0;
  font-size: 16px;
}

#storyHeader > #poweredByInstapipe > a {
  color: #999 !important;
  text-decoration: none;
}

</style>




<p style="text-align: center;"><b>⬆️ Give it a try, click on the picture ⬆️</b></p>

<style type="text/css">
  #story-available {
    margin-left: auto;
    margin-right: auto;
  }
</style>

<br />

## Background

You want to share experiences as they are happening in your life. Instagram Stories is a great way to do so, thanks to cross-posting to Facebook, Messenger and Instagram itself, allowing most people to view your stories.

However just like Snapchat, the platforms try to lock you in, with the content **you** create. Many of my family members and close friends don't use FB/IG daily, but still wanted to stay up to date on what I'm up to.

Due to lack of an official API, and any kinds of integrations, the only way to access your stories is through the unofficial API the Instagram mobile- and web client use.

## Solution

[![](https://img.shields.io/badge/author-@KrauseFx-blue.svg?style=flat)](https://twitter.com/KrauseFx)

A simple web service that automatically downloads and publishes your stories on various platforms. It's open source and fully self hosted, check it out [on GitHub](https://github.com/KrauseFx/instapipe).

### Embed into websites

<a href="https://whereisfelix.today">
  <img src="assets/whereisfelixScreenshot.jpg" />
</a>

Showing what you're up to on the websites you operate is an easy way to make your online presence more personal.

- [On whereisfelix.today](https://whereisfelix.today)
- [Integrated into krausefx.com](https://krausefx.com) (desktop only)
- [Plain live demo](https://krausefx.github.io/instapipe/web/index.html)
- [Top of this page]("#")

**Features**

- Design similar to instagram.com web
- Arrow keys to go back and forth between stories
- Support for photos and videos
- Support for desktop and mobile browsers
- Dismiss stories using ESC key, and clicking the dimmed area
- Pre-loading of the next story for instant rendering
- Basic features like rendering of the progress bar, the relative time stamp, as well as linking to your profile
- Zero dependencies, plain JavaScript, CSS and HTML in a single file

### Provide a JSON API

Of course it also provides you with a JSON API, that can be used to integrate your Instagram stories into any app or service. The API includes all relevant data, including the raw image, location and the exact resolution of the media assets.

<img src="assets/apiScreenshot.jpg" />

[https://instapipe.herokuapp.com/stories.json?user_id=4409072](https://instapipe.herokuapp.com/stories.json?user_id=4409072)

Make sure to manually copy & paste this in a new tab to avoid the cross-site scripting protection

### Telegram group

Many of my friends don't want to check Instagram every day, but still want to stay up to date with what I'm up to. Since they all use Telegram already, I set up a channel that automatically shows the stories I post.

<a href="https://t.me/joinchat/AAAAAFADGfZcXqQj3TK73A">
  <img src="assets/telegramScreenshot.jpg" />
</a>

A [Telegram group](https://t.me/joinchat/AAAAAFADGfZcXqQj3TK73A) containing all my latest stories. In particular nice to get an overview over all your most recent stories. Join it [here](https://t.me/joinchat/AAAAAFADGfZcXqQj3TK73A).

## How it works

Instapipe is a simple server, that periodically fetches your most recent Instagram stories. As soon as a new story is available, it will

- Download the highest resolution photo/video and store it on your personal Google Cloud Bucket
- Store the associated metadata in a database you own, the data includes
  - 24 hours signed URL to the full-resolution photo/video of your Google Cloud Storage
  - The full path of the resource referencing your Google Cloud bucket
  - The user ID who published the asset
  - The height and width of the photo/video
  - The exact time stamp of publishing
  - An `is_video` flag
  - The location (if a location tag is attached)
    - Location Name (e.g. `Das Gym`)
    - `lat` and `lng` coordinates
- Post the new story into a Telegram group ([check it out here](https://t.me/joinchat/AAAAAFADGfZcXqQj3TK73A))

<img src="assets/databaseScreenshot.jpg" />

At the same time, some very basic metrics will be stored:

- Per day, how many people watched at least one story (not unique users, if a user watches at least one twice, it will be counted twice)
- Per day, how many times were the stories pre-fetched (meaning the instapipe code was loaded)

The above metrics should only give you a rough idea on how many people have watched stories, no personal data is stored from the users, I don't want this to be the reason to add a cookie warning to a website.

## Can I use it?

For now, you'll have to be an engineer to be able to use it, as instapipe.net is completely self-hosted. Check out the [GitHub repo](https://github.com/krausefx/instapipe) to access instructions and the source code, in particular [`DEVELOPMENT.md`](https://github.com/KrauseFx/instapipe/blob/master/DEVELOPMENT.md).

If you're not an engineer, and are interested in using this on your website, via a Telegram channel or another platform, please drop me a message on [Twitter@KrauseFx](https://twitter.com/KrauseFx) or [Instagram@KrauseFx](https://instagram.com/KrauseFx), so I can see if demand is there to put in the extra work to provide instapipe as a service.

## Potential

This is just the beginning, highly optimized for what I needed the bot for. There are so many other interesting things that could be built on top.

### Plug & Play integrations

Right now Telegram and the API are hard-coded. However ideally you could write plugins or integrations to pipe the data over to any other platform. Maybe even an integration with [IFTTT](https://ifttt.com) would make sense ([#13](https://github.com/KrauseFx/instapipe/issues/13)).

### Multi-user support

Right now, this project only supports a single user at a time. It's designed in a way to support any number of users in the future ([#22](https://github.com/KrauseFx/instapipe/issues/new)).

### Rendering of a map/globe

A map or a 3D globe, moving around, as the stories are rendered or maybe even a map view, with the stories on the map, onclick renders the story ([#12](https://github.com/KrauseFx/instapipe/issues/12)).

### Embed pinned stories

Integrating your pinned stories onto your website would be a cool feature, however I didn't need it for myself ([#3](https://github.com/KrauseFx/instapipe/issues/3)).

### Provide RSS feed

Publishing an RSS feed would be an easy way to integrate into various services, including IFTTT ([#6](https://github.com/KrauseFx/instapipe/issues/6)).

<br />

<p style="margin-bottom: 0px;">
  <small>Website generated using <a href="https://markdown-to-github-style-web.com/" target="_blank">markdown-to-html-github-style.com</a></small></p>
