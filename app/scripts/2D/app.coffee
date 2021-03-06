NNode = require("./NNode")

module.exports = new
class App extends NNode
  constructor: ()->
    super
    # HACK: Make keyboard events on sliders work
    @superHackySliderKeyboardHack()
    require("./EarthquakeLayerManager")
    require("./BoundariesLayerManager")
    require("./BaseMapLayerManager")
    require("./ScaffoldLayerManager")
    require("./ControlsManager")
    require("./MapKeyController")
    require("./MapPerspectiveManager")
    require("./HashController")

  superHackySliderKeyboardHack: ()->
    # HACK HACK HACK HACK HACK HACK Please remove when the keyboard actually works
    $("#slider-wrapper .ui-slider-handle").keydown (event)->
      input = $(this).parents(".ui-slider").find("input")
      switch event.keyCode
        when $.mobile.keyCode.HOME
          newValue = parseFloat(input.attr("min"))
        when $.mobile.keyCode.END
          newValue = parseFloat(input.attr("max"))
        when $.mobile.keyCode.PAGE_UP, $.mobile.keyCode.UP, $.mobile.keyCode.LEFT
          newValue = parseFloat(input.val()) - parseFloat(input.attr("step"))
        when $.mobile.keyCode.PAGE_DOWN, $.mobile.keyCode.DOWN, $.mobile.keyCode.RIGHT
          newValue = parseFloat(input.val()) + parseFloat(input.attr("step"))
        else return
      input.val(newValue)
      $(input).slider("refresh")
