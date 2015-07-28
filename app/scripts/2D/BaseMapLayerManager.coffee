###
A class to swap out different base maps
Note: There's supposed to be a controller and provider that feeds into here, but NOTE: I've
skipped them both for rapid prototyping.
###

NNode = require("./NNode")
BaseMapSelectorUI = require("./BaseMapSelectorUI")
MapView = require("./MapView")
SessionController = require("./SessionController")

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

    @sessionController = SessionController

    # Hold current and previously displaying map type
    @baseLayer = "satellite"
    @previousBaseLayer = null

    # Rig up that map view
    @mapView = MapView

    # Connect that selector
    @baseMapSelector = BaseMapSelectorUI

    # Rig up that switching
    @baseMapSelector.subscribe "update", (value)=>
      @baseLayer = value
      @updateBaseLayer()
      @updateSession()

    @sessionController.subscribe "update", (updates)=>
      if "baseLayer" of updates
        {@baseLayer} = updates
        @updateBaseLayer()

    @updateBaseLayer()
    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @baseLayer
    }

  updateBaseLayer: ()->
    @baseMapSelector.tell "set", @baseLayer

    if @previousBaseLayer isnt @baseLayer
      # Switcheroo
      @mapView.tell "remove-layer", @getLayer(@previousBaseLayer) if @previousBaseLayer?
      @mapView.tell "add-layer",  @getLayer(@baseLayer)
      @previousBaseLayer = @baseLayer

  getLayer: (name)->
    return switch name
      when "street" then @streetMap
      when "satellite" then @satelliteMap
      when "density" then @earthquakeDensityMap
