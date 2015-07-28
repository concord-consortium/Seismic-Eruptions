NNode = require("./NNode")

module.exports = new
class DateRangeSliderUI extends NNode
  constructor: ()->
    super

    preventChangeFromHappenningHack = no

    # Rig up those date sliders
    @dateSliderStart = $("#date-slider-start")
    @dateSliderEnd = $("#date-slider-end")
    @dateSliderReadout = $("#date-slider-readout")

    # Configure them based on options
    @listen "configure", (options)=>
      {minYear, maxYear, yearStep} = options
      @dateSliderStart.add(@dateSliderEnd)
        .attr("min", minYear).attr("max", maxYear).attr("step", yearStep)

    @listen "set", (startVal, endVal)=>
      preventChangeFromHappenningHack = yes
      @dateSliderStart.val(startVal)
      @dateSliderEnd.val(endVal)
      @dateSliderStart.add(@dateSliderEnd).slider("refresh")
      preventChangeFromHappenningHack = no

    # Rig up some events
    @dateSliderStart.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update-start", parseInt(@dateSliderStart.val())

    @dateSliderEnd.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update-end", parseInt(@dateSliderEnd.val())

    @listen "set-text", (text)=>
      @dateSliderReadout.text(text)
