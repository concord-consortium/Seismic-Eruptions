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
        marker.clickable = true

        # Decide whether we want a popup or not
        marker.bindPopup("""
          #{featureData.properties.label}<br>
          <a href="" onclick="window.location.hash=\
          'scaffold:#{featureData.properties.scaffold}'">Go!</a>
        """)
        # marker.on "click", ()->
        #   window.location.hash = "scaffold:#{featureData.properties.scaffold}"
    }

    @mapView.tell "add-layer", @scaffoldLayer
