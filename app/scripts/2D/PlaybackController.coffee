###
PlaybackController
A class to manage playing, pausing, speeding up, and slowing down.
Communicates with the UI's buttons and timeline slider.
###
PlaybackButtonsUI = require("./PlaybackButtonsUI")
PlaybackSliderUI = require("./PlaybackSliderUI")
NNode = require("./NNode")

module.exports =
class PlaybackController extends NNode
  ###
  Creates a new PlaybackController.
  Also rigs up the provided UI elements.
  ###
  constructor: ()->
    super
    # A TimelineLite is used to handle internal timing
    @timeline = new TimelineLite({
      onUpdate: ()=> # When updating timeline, tell others
        progress = @timeline.progress()
        @post "update", progress
        @playbackSlider.tell "set", progress
        if progress is 1
          @pauseOnly()
      , paused: true # Pause after creation - no timeline should run away on my watch
    })

    @duration = 16 # 1 playthrough per 20 seconds
    @_updateTimelineScale()

    # Pause the timeline at progress = 1 (the end)
    @timeline.addPause(1)

    # Hook up some buttons
    @playbackButtons = new PlaybackButtonsUI()

    # Listen for control messages from the buttons
    @playbackButtons.subscribe "update", (which)=>
      switch which
        when "slowdown" then @slowDown()
        when "playpause" then @playPause()
        when "speedup" then @speedUp()

    # Hook up that slider
    @playbackSlider = new PlaybackSliderUI()

    # Listen for control messages from the slider
    # to set playback progress
    @playbackSlider.subscribe "update", (progress)=>
      @pauseOnly()
      @timeline.progress(progress)

    # Listen to set the timeline progress
    @listen "set", (value)=>
      @timeline.progress(value)

    # Listen to change the slider text
    @listen "set-text", (text)=>
      @playbackSlider.tell "set-text", text

    # Listen to change the slider step
    @listen "set-step", (step)=>
      @playbackSlider.tell "set-step", step

  ###
  Standard playback control methods. Does what you expect them to do.
  ###
  slowDown: ()->
    @duration *= 2 if @duration < 128
    @_updateTimelineScale()

  speedUp: ()->
    @duration /= 2 if @duration > 2
    @_updateTimelineScale()

  pauseOnly: ()->
    @timeline.pause()
    @playbackButtons.tell "set-play-or-pause", "play"

  playPause: ()->
    if @timeline.isActive()
      # Was playing, now transition to paused
      @pauseOnly()
    else
      # Was paused, now transition to playing
      # Restart if necessary
      if @timeline.progress() is 1
        @timeline.restart()
      else
        @timeline.play()
      @playbackButtons.tell "set-play-or-pause", "pause"

  _updateTimelineScale: ()->
    @timeline.timeScale(1 / @duration)
