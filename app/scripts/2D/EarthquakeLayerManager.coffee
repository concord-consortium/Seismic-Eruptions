###
EarthquakeLayerManager - A class to manage the Leaflet earthquake layer and populate it with points
from the filters that lead into it
TODO: HORRIBLY INCOMPLETE
###

NNode = require("./NNode")
DateFilter = require("./DateFilter")
MapView = require("./MapView")
module.exports = new
class EarthquakeLayerManager extends NNode
  constructor: ()->
    super

    # Rig up the source filter
    @inputNode = DateFilter

    # Rig up the map view node
    @mapView = MapView
    # Here's where the current layer of earthquakes will be stored
    @earthquakesLayer = null

    # Keep a cache, just in case.
    @cachedData = []

    @inputNode.subscribe "stream", (newData)=>
      # Event upon incrementally receiving a new data chunk from the source

      # Add the new data to the map!
      for point in newData
        @cachedData.push(point)
      @addToLayer(newData)

    @inputNode.subscribe "flush", (freshData)=>
      # Incoming data has changed in a way that the current cache
      # is out of date, and may contain points irrelevant to the stream. Thus, purge the cache
      # and refill with fresh data. Also, refill the next filter with fresh data too.
      @cachedData = freshData
      @flushLayer(freshData)

    @flushLayer()

    # temporary variable to hold the setTimeout ID
    # that defers repopulation of the the flushed layer
    @flushDeferTimer = null

  # How long to wait after flush to repopulate the layer
  @FLUSH_DEFER_TIME: 300

  ###
  Pretty self-explanatory, eh?
  ###
  addToLayer: (data)->
    @earthquakesLayer.addData(data)

  ###
  Removes the current, stale layer and replaces it with a new, fresh, empty one.
  Also used to intitialize the layer.

  NOTE: Defer re-adding fresh data to the layer
  ###
  flushLayer: (freshData)->
    if @earthquakesLayer?
      @mapView.tell "remove-layer", @earthquakesLayer

    # Find a better home for this rainbow?
    rainbow = new Rainbow()
    rainbow.setNumberRange(0, 700)

    # Here's where the styling occurs
    @earthquakesLayer = L.geoJson [], {
      pointToLayer: (feature, latlng) ->
        depth = feature.geometry.coordinates[2]
        magnitude = feature.properties.mag
        style = {
          fillOpacity: 0.6
          fillColor: "#" + rainbow.colourAt(depth)
          radius: 0.9 * Math.pow(1.5, (magnitude - 1))
          stroke: no
        }
        return L.circleMarker(latlng, style)
    }

    @mapView.tell "add-layer", @earthquakesLayer

    if freshData?
      clearTimeout(@flushDeferTimer) if @flushDeferTimer?

      @flushDeferTimer = setTimeout ()=>
        @addToLayer(freshData)
      , EarthquakeLayerManager.FLUSH_DEFER_TIME
