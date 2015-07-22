###
MapView - a class for creating a leaflet map and exposing parts of the map
as an interface to child classes
###
NNode = require("./NNode")

module.exports = new
class MapView extends NNode
  constructor: ()->
    super
    window.l = @leafletMap = L.map("map", {worldCopyJump: true})

    # TODO: Move this into LocationManager
    @leafletMap.fitBounds(L.latLngBounds(L.latLng(-50, -40), L.latLng(50, 40)))

    # TODO: Move this into BaseMapManager
    @leafletMap.addLayer L.tileLayer('http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png',
      {subdomains: ['otile1', 'otile2', 'otile3', 'otile4']})

    @leafletMap.invalidateSize(true)

    @listen "add-layer", (layer)=>
      @leafletMap.addLayer(layer)

    @listen "remove-layer", (layer)=>
      @leafletMap.removeLayer(layer)
