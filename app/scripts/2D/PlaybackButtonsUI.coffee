###
A small class to manage the playback buttons
###

NNode = require("./NNode")


module.exports = new
class PlaybackButtonsUI extends NNode

  constructor: ()->
    super
    @slowDown = $("#slowdown")
    @playPause = $("#playpause")
    @speedUp = $("#speedup")

    # Rig up those events
    @slowDown.click ()=>
      @post "update", "slowdown"
    @playPause.click ()=>
      @post "update", "playpause"
    @speedUp.click ()=>
      @post "update", "speedup"

    @listen "set-play-or-pause", (playOrPause)->
      switch playOrPause
        when "play" then @becomePlayButton()
        when "pause" then @becomePauseButton()

  becomePlayButton: ()->
    @playPause.removeClass("ui-icon-fa-pause")
    @playPause.addClass("ui-icon-fa-play")

  becomePauseButton: ()->
    @playPause.addClass("ui-icon-fa-pause")
    @playPause.removeClass("ui-icon-fa-play")
