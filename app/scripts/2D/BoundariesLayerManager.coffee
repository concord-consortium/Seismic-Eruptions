###
A class to add or remove the boundaries layer
Note: There's supposed to be a controller and provider that feeds into here, but NOTE: I've
skipped them both for rapid prototyping.
###

NNode = require("./NNode")
BoundariesToggleUI = require("./BoundariesToggleUI")
MapView = require("./MapView")
SessionController = require("./SessionController")

module.exports = new
class BoundariesLayerManager extends NNode
  constructor: ()->
    super
    # Load up that boundaries kml layer
    @boundariesLayer = new L.KML("plates.kml", {async: true})

    # Hold previously displaying state
    @boundariesVisible = false
    @boundariesPreviouslyVisible = false

    @sessionController = SessionController

    # Rig up that map view
    @mapView = MapView

    # Connect that toggle switch
    @boundariesToggle = BoundariesToggleUI

    @boundariesToggle.subscribe "update", (value)=>
      @boundariesVisible = value
      @updateBoundaries()
      @updateSession()

    @sessionController.subscribe "update", (session)=>
      {
        @boundariesVisible
      } = session
      @updateBoundaries()

    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @boundariesVisible
    }

  updateBoundaries: ()->
    @boundariesToggle.tell "set", @boundariesVisible

    if @boundariesVisible
      @mapView.tell "add-layer", @boundariesLayer unless @boundariesPreviouslyVisible
    else
      @mapView.tell "remove-layer", @boundariesLayer if @boundariesPreviouslyVisible
    @boundariesPreviouslyVisible = @boundariesVisible
