###
Manages the showing/hiding of the bottom bar
###

NNode = require("./NNode")
ControlsUI = require("./ControlsUI")

module.exports = new
class App extends NNode
  constructor: ()->
    super
    @controlsUI = ControlsUI

    # Holds whether or not the controls are visible
    @controlsVisible = yes

    @controls = $("#controls")

    # Any time either show/hide is pressed, toggle.
    # I'd believe it's more robust - we don't discriminate which button
    @controlsUI.subscribe "update", ()=>
      # Toggle control visibility
      if @controlsVisible
        @controls.finish().slideUp(500)
      else
        @controls.finish().slideDown(500)

      @controlsVisible = !@controlsVisible
