###
A class to manage the magnitude filter, tying together the UI
and the data filter
###
NNode = require("./NNode")
MagnitudeSliderUI = require("./MagnitudeSliderUI")
DataFormatter = require("./DataFormatter")

module.exports = new
class MagnitudeFilterController extends NNode
  @MIN_MAGNITUDE: 3
  @MAX_MAGNITUDE: 9
  constructor: ()->
    super
    @minMagnitude = 5

    # Create and hook up a display options panel
    @uiMagnitudeSlider = MagnitudeSliderUI
    @uiMagnitudeSlider.subscribe "update", (value)=>
      @minMagnitude = value
      @postControllerChanges()
      @updateMagnitudeSlider()

    @uiMagnitudeSlider.tell "configure", {
      minMagnitude: MagnitudeFilterController.MIN_MAGNITUDE
      maxMagnitude: MagnitudeFilterController.MAX_MAGNITUDE
      magnitudeStep: 0.1
      initialMinMagnitude: @minMagnitude
    }

    @updateMagnitudeSlider()

    # When requested, update
    @listen "request-update", @postControllerChanges

  # Tells everyone that the filter has changed
  postControllerChanges: ()->
    @post "update", {
      minMagnitude: @minMagnitude
    }

  # Tell the magnitude slider what to be set as
  # in the format (sliderValue, textToDisplay)
  updateMagnitudeSlider: ()->
    @uiMagnitudeSlider.tell "set-text", "#{DataFormatter.formatMagnitude(@minMagnitude)}"
