###
A small class to hook up the playback slider
###

NNode = require("./NNode")

module.exports =
class PlaybackSliderUI extends NNode

  constructor: ()->
    super
    # Jump through some hoops because jQuery mobile's slide event doesn't seem to work.
    # HACK: Use a variable to prevent change code from firing when
    # programatically adjusting value.

    preventChangeFromHappenningHack = no

    @slider = $("#slider")
    @sliderHandle = $("#slider-wrapper .ui-slider-handle")

    # Rig up some events
    @slider.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update", parseFloat(@slider.val())

    @listen "set", (value)=>
      preventChangeFromHappenningHack = yes
      @slider.val(value).slider("refresh")
      preventChangeFromHappenningHack = no

    @listen "set-text", (text)=>
      @sliderHandle.text(text)
      @sliderHandle.attr("title", text)

    @listen "set-step", (step)=>
      @slider.attr("step", step)
