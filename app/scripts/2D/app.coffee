NNode = require("./NNode")

module.exports =
class App extends NNode
  constructor: ()->
    super
    $(document).on "ready", ()=>
      # HACK: Make keyboard events on sliders work
      @superHackySliderKeyboardHack()
      require("./EarthquakeLayerManager")
      require("./BoundariesLayerManager")
      require("./BaseMapLayerManager")
  superHackySliderKeyboardHack: ()->
    # HACK HACK HACK HACK HACK HACK Please remove when the keyboard actually works
    $("#slider-wrapper .ui-slider-handle").keydown (event)->
      input = $(this).parents(".ui-slider").find("input")
      input.val switch event.keyCode
        when $.mobile.keyCode.HOME
          parseFloat(input.attr("min"))
        when $.mobile.keyCode.END
          parseFloat(input.attr("max"))
        when $.mobile.keyCode.PAGE_UP, $.mobile.keyCode.UP, $.mobile.keyCode.LEFT
          parseFloat(input.val()) - parseFloat(input.attr("step"))
        when $.mobile.keyCode.PAGE_DOWN, $.mobile.keyCode.DOWN, $.mobile.keyCode.RIGHT
          parseFloat(input.val()) + parseFloat(input.attr("step"))
      $(input).slider("refresh")
