NNode = require("./NNode")

module.exports =
class MagnitudeSliderUI extends NNode
  constructor: ()->
    super
    # Same hack as PlaybackSliderUI
    preventChangeFromHappenningHack = no

    # Rig up those magnitude sliders
    @magnitudeSlider = $("#magnitude-slider")
    @magnitudeSliderReadout = $("#magnitude-readout")
    @magnitudeSlider.on "change", ()=>
      unless preventChangeFromHappenningHack
        @tellEveryone "magnitude-change", parseFloat(@magnitudeSlider.val())

    # When magnitude filter is updated, adjust the readout and tweak the slider value
    @listen "magnitude-filter-update", (sliderVal, text)->
      preventChangeFromHappenningHack = yes
      @magnitudeSlider.val(sliderVal).slider("refresh")
      @magnitudeSliderReadout.text(text)
      preventChangeFromHappenningHack = no
