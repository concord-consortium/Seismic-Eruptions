###
PlaybackController
A class to manage playing, pausing, speeding up, and slowing down.
Communicates with the UI's buttons and timeline slider.
###
UIPlaybackButtons = require("./UIPlaybackButtons")
UIPlaybackSlider = require("./UIPlaybackSlider")
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
        @tellOthers "playback-update", @timeline.progress()
      , paused: true # Pause after creation - no timeline should run away on my watch
    })

    @duration = 10 # 1 playthrough per 20 seconds
    @_updateTimelineScale()

    # Pause the timeline at progress = 1 (the end)
    @timeline.addPause(1)

    # Hook up some buttons
    @playbackButtons = new UIPlaybackButtons()
    @connect(@playbackButtons)

    # Listen for control messages from the buttons
    @listen "playback-controls", (which)=>
      switch which
        when "slowdown" then @slowDown()
        when "playpause" then @playPause()
        when "speedup" then @speedUp()

    # Hook up that slider
    @playbackSlider = new UIPlaybackSlider()
    @connect(@playbackSlider)

    # Listen for control messages from the slider
    # to set playback progress
    @listen "playback-set", (progress)=>
      @pauseOnly()
      @timeline.progress(progress)

  ###
  Standard playback control methods. Does what you expect them to do.
  ###
  slowDown: ()->
    @duration *= 2
    @_updateTimelineScale()

  pauseOnly: ()->
    @timeline.pause()
    @tellOthers "playback-change", "pause"

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
      @tellOthers "playback-change", "play"

  speedUp: ()->
    @duration /= 2 if @duration > 1
    @_updateTimelineScale()

  _updateTimelineScale: ()->
    @timeline.timeScale(1 / @duration)
