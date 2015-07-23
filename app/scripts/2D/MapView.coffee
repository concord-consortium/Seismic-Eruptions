###
MapView - a class for creating a leaflet map and exposing parts of the map
as an interface to child classes
###
NNode = require("./NNode")

module.exports = new
class MapView extends NNode
  constructor: ()->
    super
    @leafletMap = L.map("map", {worldCopyJump: true})

    # TODO: Move this into LocationManager

    $(window).on "load", ()=>
      @leafletMap.fitBounds(L.latLngBounds(L.latLng(-50, -40), L.latLng(50, 40)))
      @leafletMap.invalidateSize(true)

    @listen "add-layer", (layer)=>
      @leafletMap.addLayer(layer)

    @listen "remove-layer", (layer)=>
      @leafletMap.removeLayer(layer)
