###
EarthquakeLayerManager - A class to manage the Leaflet earthquake layer and populate it with points
from the filters that lead into it
TODO: HORRIBLY INCOMPLETE
###

NNode = require("./NNode")
DateFilter = require("./DateFilter")

module.exports =
class EarthquakeLayerManager extends NNode
  constructor: ()->
    super

    # Here's where all the data that enters the manager will be stored (for now).
    @cachedData = []

    # Rig up the source filter
    @inputNode = new DateFilter()

    @inputNode.subscribe "stream", (newData)=>
      # Event upon incrementally receiving a new data chunk from the source

      # First, cache it up!
      for point in newData
        @cachedData.push(point)

      console.log("#{@cachedData.length} earthquakes on the map")

    @inputNode.subscribe "flush", (freshData)=>
      # Incoming data has changed in a way that the current cache
      # is out of date, and may contain points irrelevant to the stream. Thus, purge the cache
      # and refill with fresh data. Also, refill the next filter with fresh data too.
      @cachedData = freshData

      console.log("#{@cachedData.length} earthquakes on the map")
