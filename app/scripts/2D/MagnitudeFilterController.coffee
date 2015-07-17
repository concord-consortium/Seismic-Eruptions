###
A class to manage the magnitude filter, tying together the UI
and the data filter
###
NNode = require("./NNode")
PlaybackController = require("./PlaybackController")
MagnitudeSliderUI = require("./MagnitudeSliderUI")
Utils = require("./Utils")

module.exports =
class MagnitudeFilterController extends NNode
  @MIN_MAGNITUDE: 3
  @MAX_MAGNITUDE: 9
  constructor: ()->
    super
    @magnitude = 5

    # Create and hook up a display options panel
    @uiMagnitudeSlider = new MagnitudeSliderUI()
    @connect(@uiMagnitudeSlider)
    @listen "magnitude-change", (end)->
      @magnitude = Utils.expandNorm(end,
        MagnitudeFilterController.MIN_MAGNITUDE, MagnitudeFilterController.MAX_MAGNITUDE)
      @tellEveryoneFilter()
      @tellMagnitude()

    @tellMagnitude()
    @tellEveryoneFilter()

  # Tells everyone that the filter has changed
  tellEveryoneFilter: ()->
    @tellEveryone "filter-update", this

  # Tell the magnitude slider what to be set as
  # in the format (sliderValue, textToDisplay)
  tellMagnitude: ()->
    @tellEveryone "magnitude-filter-update",
      Utils.contractNorm(@magnitude,
        MagnitudeFilterController.MIN_MAGNITUDE, MagnitudeFilterController.MAX_MAGNITUDE),
      "#{@magnitude.toFixed(1)}"
