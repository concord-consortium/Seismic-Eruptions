###
A class to manage the scaffold layer
###

NNode = require("./NNode")
ScaffoldController = require("./ScaffoldController")
MapView = require("./MapView")

module.exports = new
class ScaffoldLayerManager extends NNode

  constructor: ()->
    super

    @mapView = MapView

    @scaffoldLayer = null

    @scaffoldController = ScaffoldController

    @scaffoldController.subscribe "update", (features)=>
      @buildLayer(features)

  buildLayer: (features)->
    if @scaffoldLayer?
      @mapView.tell "remove-layer", @scaffoldLayer

    # Here's where some formatting magic occurs
    @scaffoldLayer = L.geoJson features, {
      onEachFeature: (featureData, marker)->
        marker.bindPopup("#{featureData.properties.label}", {closeButton: false, offset: new L.Point(0, 0)})

        marker.on 'click', (e)->
          window.location.hash = "scaffold:#{featureData.properties.scaffold}"
          # Click automatically opens popup, but we don't need it, as it happens on mouseover.
          marker.closePopup()

        marker.on 'mouseover', ()->
          b = marker.getBounds()
          marker.openPopup(new L.LatLng(b.getNorth(), b.getCenter().lng))

        marker.on 'mouseout', ()->
          marker.closePopup()
    }

    @mapView.tell "add-layer", @scaffoldLayer
