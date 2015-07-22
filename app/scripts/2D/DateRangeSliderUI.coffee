NNode = require("./NNode")

module.exports = new
class DateRangeSliderUI extends NNode
  constructor: ()->
    super

    # Rig up those date sliders
    @dateSliderStart = $("#date-slider-start")
    @dateSliderEnd = $("#date-slider-end")
    @dateSliderReadout = $("#date-slider-readout")

    # Configure them based on options
    @listen "configure", (options)=>
      {startYear, endYear, yearStep, initialStartYear, initialEndYear} = options
      @dateSliderStart.add(@dateSliderEnd)
        .attr("min", startYear).attr("max", endYear).attr("step", yearStep)
      @dateSliderStart.val(initialStartYear)
      @dateSliderEnd.val(initialEndYear)
      @dateSliderStart.add(@dateSliderEnd).slider("refresh")

    # Rig up some events
    @dateSliderStart.on "change", ()=>
      @post "update-start", parseInt(@dateSliderStart.val())

    @dateSliderEnd.on "change", ()=>
      @post "update-end", parseInt(@dateSliderEnd.val())

    @listen "set-text", (text)=>
      @dateSliderReadout.text(text)
