###
MagnitudeFilter - a class to receive a bunch of earthquakes, and pass on the ones that are greater
than a specified magnitude

See DateFilter's header comment for more info on filters.
###

NNode = require("./NNode")
CacheFilter = require("./CacheFilter")
MagnitudeFilterController = require("./MagnitudeFilterController")

module.exports = new
class MagnitudeFilter extends NNode
  constructor: ()->
    super

    # Rig up a controller
    @controller = MagnitudeFilterController

    @startMagnitude = -Infinity
    @endMagnitude = Infinity

    @controller.subscribe "update", (updatedFilter) =>
      # Shim so I can write less code
      updatedFilter.endMagnitude = Infinity

      # Event when the controller has updated parameters.
      if updatedFilter.startMagnitude > @startMagnitude or
      updatedFilter.endMagnitude < @endMagnitude

        # Filter region has shrunk, thus data may be invalid

        @post "flush", @filterMagnitudes(@cachedData, updatedFilter.startMagnitude,
          updatedFilter.endMagnitude)

      else
        # Filter region has grown
        # Create an array to be filled with additional data points
        additionalPoints = []

        # Append to that array all new points on (possibly) both ends of the new range
        @filterMagnitudes @cachedData, updatedFilter.startMagnitude, @startMagnitude,
          additionalPoints
        @filterMagnitudes @cachedData, @endMagnitude, updatedFilter.endMagnitude, additionalPoints

        # Stream the new data to the further filters
        @post "stream", additionalPoints if additionalPoints.length > 0

      # Update current filter state
      @startMagnitude = updatedFilter.startMagnitude
      @endMagnitude = updatedFilter.endMagnitude

    # Here's where all the data that enters the filter will be stored.
    @cachedData = []

    # Rig up the source filter
    @inputNode = CacheFilter

    @inputNode.subscribe "stream", (newData)=>
      # Event upon incrementally receiving a new data chunk from the source

      # First, cache it up!
      for point in newData
        @cachedData.push(point)

      # Then, stream it on!
      @post "stream", @filterMagnitudes(newData, @startMagnitude, @endMagnitude)

    @inputNode.subscribe "flush", (freshData)=>
      # Incoming data has changed in a way that the current cache
      # is out of date, and may contain points irrelevant to the stream. Thus, purge the cache
      # and refill with fresh data. Also, refill the next filter with fresh data too.
      @cachedData = freshData
      @post "flush", @filterMagnitudes(@cachedData, @startMagnitude, @endMagnitude)

  ###
  Creates a new array and fills it with the dataset, diced with given parameters
  Note: startMagnitude is inclusive, endMagnitude is exclusive
  ###
  filterMagnitudes: (data, startMagnitude, endMagnitude, newArray = [])->
    # NOTE: This is where the filter MAGIC happens
    for point in data
      if startMagnitude <= point.properties.mag < endMagnitude
        newArray.push(point)
    return newArray
