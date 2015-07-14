NNode = require("./NNode")

slowDown = $("#slowdown")
playPause = $("#playpause")
speedUp = $("#speedup")

module.exports =
class UIPlaybackButtons extends NNode

  constructor: ()->
    super
    slowDown.click ()=>
      @tellOthers("playback-controls", "slowdown")
    playPause.click ()=>
      @tellOthers("playback-controls", "playpause")
    speedUp.click ()=>
      @tellOthers("playback-controls", "speedup")

    @listen "playback-change", (playOrPause)->
      switch playOrPause
        when "play" then @becomePauseButton()
        when "pause" then @becomePlayButton()

  becomePlayButton: ()->
    playPause.removeClass("ui-icon-fa-pause")
    playPause.addClass("ui-icon-fa-play")

  becomePauseButton: ()->
    playPause.addClass("ui-icon-fa-pause")
    playPause.removeClass("ui-icon-fa-play")
