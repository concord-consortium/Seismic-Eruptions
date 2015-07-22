###
A class to swap out different base maps
Note: There's supposed to be a controller and provider that feeds into here, but NOTE: I've
skipped them both for rapid prototyping.
###

NNode = require("./NNode")
BaseMapSelectorUI = require("./BaseMapSelectorUI")
MapView = require("./MapView")

module.exports = new
class BaseMapLayerManager extends NNode
  constructor: ()->
    super
    # Load up those map tile layers
    @streetMap = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {})
    @satelliteMap = L.tileLayer('http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png',
      {subdomains: ['otile1', 'otile2', 'otile3', 'otile4']})
    @earthquakeDensityMap =
      L.tileLayer('http://{s}.tiles.mapbox.com/v3/bclc-apec.map-rslgvy56/{z}/{x}/{y}.png', {})

    # Hold previously (currently) displaying map type
    @previouslyDisplaying = @satelliteMap

    # Rig up that map view
    @mapView = MapView

    # Connect that selector
    @baseMapSelector = BaseMapSelectorUI

    # Rig up that switching
    @mapView.tell "add-layer", @satelliteMap

    @baseMapSelector.subscribe "update", (value)=>
      # Switcheroo
      @mapView.tell "remove-layer", @previouslyDisplaying

      @mapView.tell "add-layer", @previouslyDisplaying = switch value
        when "street" then @streetMap
        when "satellite" then @satelliteMap
        when "density" then @earthquakeDensityMap
