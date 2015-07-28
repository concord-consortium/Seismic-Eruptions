###
CacheFilter - a class to receive data from the web and cache it all up, and serve it to the filters
that come after.

NOTE: The cache functionality has been deactivated for now, because there is no spacial filter yet
###

NNode = require("./NNode")
EarthquakeProvider = require("./EarthquakeProvider")

module.exports = new
class CacheFilter extends NNode
  constructor: ()->
    super
    # Here's where all the data that enters the filter will be stored.
    @cachedData = []

    # Rig up the source filter
    @inputNode = EarthquakeProvider

    @inputNode.subscribe "stream", (newData)=>
      # Event upon incrementally receiving a new data chunk from the source
      @post "flush", newData
      # streamedArray = []

      # Ignore points that already exist in the cache
      # for point in newData
      #   unless @cachedDataContains(point)
      #     @cachedData.push(point)
      #     streamedArray.push(point)

      # Then, stream it on!
      # @post "stream", streamedArray

  # TODO: make more efficient, or just remove entirely
  # cachedDataContains: (point)->
  #   for check in @cachedData
  #     if check.id is point.id
  #       return true
  #   return false
