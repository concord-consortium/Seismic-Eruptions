###
MapView - a class for creating a leaflet map and exposing parts of the map
as an interface to child classes
###
NNode = require("./NNode")

module.exports = new
class MapView extends NNode
  constructor: ()->
    super
    @leafletMap = L.map("map")

    # TODO: Move this into LocationManager

    @frozen = null

    $(window).on "load", ()=>
      @leafletMap.invalidateSize()
      @post "loaded"
      # Rig up map movement (and "freezing")
      @leafletMap.on "moveend", ()=>
        unless @frozen
          @post "bounds-update", @leafletMap.getBounds()

    @listen "add-layer", (layer)=>
      @leafletMap.addLayer(layer)

    @listen "remove-layer", (layer)=>
      @leafletMap.removeLayer(layer)

    # Freezes the map in it's current zoom and pan level
    @listen "freeze", (bounds)=>
      @frozen = true
      @leafletMap.setMaxBounds(bounds)
      @leafletMap.options.minZoom =
      @leafletMap.options.maxZoom = @leafletMap.getBoundsZoom(bounds)

    # Unfreezes the map from it's current zoom and pan level
    @listen "unfreeze", ()=>
      @frozen = false
      @leafletMap.setMaxBounds(null)
      @leafletMap.options.minZoom = 0
      @leafletMap.options.maxZoom = 18

    # Rig up map movement updates
    @listen "set-bounds", (bounds)=>
      @leafletMap.fitBounds(bounds)
