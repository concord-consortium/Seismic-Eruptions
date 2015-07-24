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
    @showControls = $("#show-controls")

    # Any time either show/hide is pressed, toggle.
    # I'd believe it's more robust - we don't discriminate which button
    @controlsUI.subscribe "update", ()=>
      # Toggle control visibility
      @controlsVisible = !@controlsVisible

      if @controlsVisible
        @controls.finish().slideDown(300)
        @showControls.finish().fadeOut(300)
      else
        @controls.finish().slideUp(300)
        @showControls.finish().fadeIn(300)
