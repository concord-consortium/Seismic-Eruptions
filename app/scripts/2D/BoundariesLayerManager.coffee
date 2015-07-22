###
A class to add or remove the boundaries layer
Note: There's supposed to be a controller and provider that feeds into here, but NOTE: I've
skipped them both for rapid prototyping.
###

NNode = require("./NNode")
BoundariesToggleUI = require("./BoundariesToggleUI")
MapView = require("./MapView")

module.exports = new
class BoundariesLayerManager extends NNode
  constructor: ()->
    super
    # Load up that boundaries kml layer
    @boundariesLayer = new L.KML("plates.kml", {async: true})

    # Hold previously displaying state
    @previouslyDisplaying = false

    # Rig up that map view
    @mapView = MapView

    # Connect that toggle switch
    @boundariesToggle = BoundariesToggleUI

    @boundariesToggle.subscribe "update", (value)=>
      if value
        @mapView.tell "add-layer", @boundariesLayer unless @previouslyDisplaying
      else
        @mapView.tell "remove-layer", @boundariesLayer if @previouslyDisplaying

      @previouslyDisplaying = value
