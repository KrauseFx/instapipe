var storiesToShow = null;
var timeOutForPhotos = 4.0;
var storyProgressSpacing = 5;
var progressPadding = 2;
var progressBars = null;

var nextStoryTimeout = null;
var currentIndex = -1;

function showStories() {
  var url = "https://instapipe.herokuapp.com/stories.json";
  // url = "http://127.0.0.1:4567/stories.json"

  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() { 
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      var content = JSON.parse(xmlHttp.responseText)
      storiesToShow = []
      progressBars = []

      document.getElementById("storyViewer").style.display = "block"

      for (let storyIndex in content) {
        let currentStory = content[storyIndex]
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
    }
  }
  xmlHttp.open("GET", url, true); // true = asynchronous 
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

  if (currentStory["is_video"]) {
    videoViewer.src = currentStory["signed_url"]
    videoViewer.style.display = "block"
    videoViewer.onended = function() {
      currentIndex++;
      renderCurrentStory();
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
  if (currentIndex < storiesToShow.length - 2 && !storiesToShow[currentIndex + 1]["is_video"])
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
  stopAllAnimations()
  currentIndex--;
  renderCurrentStory();
}

function userDidClickNextStory() {
  stopAllAnimations()
  currentIndex++;
  renderCurrentStory();
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

// showStories()
