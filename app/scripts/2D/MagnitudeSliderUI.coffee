###
A class to manage the magnitude slider
###

NNode = require("./NNode")

module.exports = new
class MagnitudeSliderUI extends NNode
  constructor: ()->
    super
    # Same hack as PlaybackSliderUI
    preventChangeFromHappenningHack = no

    # Rig up those magnitude sliders
    @magnitudeSlider = $("#magnitude-slider")
    @magnitudeSliderReadout = $("#magnitude-readout")

    @listen "configure", (options)=>
      {minMagnitude, maxMagnitude, magnitudeStep} = options
      @magnitudeSlider
        .attr("min", minMagnitude).attr("max", maxMagnitude).attr("step", magnitudeStep)

    @magnitudeSlider.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update", parseFloat(@magnitudeSlider.val())

    # When magnitude filter is updated, adjust the readout and tweak the slider value
    @listen "set", (value)->
      preventChangeFromHappenningHack = yes
      @magnitudeSlider.val(value).slider("refresh")
      preventChangeFromHappenningHack = no

    @listen "set-text", (text)->
      @magnitudeSliderReadout.text(text)
