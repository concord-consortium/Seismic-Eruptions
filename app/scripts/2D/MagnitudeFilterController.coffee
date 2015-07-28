###
A class to manage the magnitude filter, tying together the UI
and the data filter
###
NNode = require("./NNode")
MagnitudeSliderUI = require("./MagnitudeSliderUI")
DataFormatter = require("./DataFormatter")
SessionController = require("./SessionController")

module.exports = new
class MagnitudeFilterController extends NNode
  constructor: ()->
    super
    @minMagnitude = 3
    @maxMagnitude = 9
    @startMagnitude = 5

    @sessionController = SessionController

    # Create and hook up a display options panel
    @uiMagnitudeSlider = MagnitudeSliderUI
    @uiMagnitudeSlider.subscribe "update", (value)=>
      @startMagnitude = value
      @limitMagnitudeJustInCase()
      @postControllerChanges()
      @updateMagnitudeSlider()
      @updateSession()


    @sessionController.subscribe "update", (updates)=>
      needsUpdating = no
      if "startMagnitude" of updates
        {@startMagnitude} = updates
        needsUpdating = yes
      if "minMagnitude" of updates
        {@minMagnitude} = updates
        needsUpdating = yes
      if "maxMagnitude" of updates
        {@maxMagnitude} = updates
        needsUpdating = yes
      if needsUpdating
        @limitMagnitudeJustInCase()
        @postControllerChanges()
        @updateMagnitudeSlider()

    @updateMagnitudeSlider()
    @updateSession()

    # When requested, update
    @listen "request-update", @postControllerChanges

  limitMagnitudeJustInCase: ()->
    @minMagnitude = Math.min(@minMagnitude, @maxMagnitude)
    @startMagnitude = Math.min(Math.max(@startMagnitude,
      @minMagnitude), @maxMagnitude)

  updateSession: ()->
    @sessionController.tell "append", {
      @startMagnitude
      @minMagnitude
      @maxMagnitude
    }

  # Tells everyone that the filter has changed
  postControllerChanges: ()->
    @post "update", {
      @startMagnitude
    }

  # Tell the magnitude slider what to be set as
  # in the format (sliderValue, textToDisplay)
  updateMagnitudeSlider: ()->
    @uiMagnitudeSlider.tell "configure", {
      @minMagnitude
      @maxMagnitude
      magnitudeStep: 0.1
    }
    @uiMagnitudeSlider.tell "set-text", "#{DataFormatter.formatMagnitude(@startMagnitude)}"
    @uiMagnitudeSlider.tell "set", @startMagnitude
