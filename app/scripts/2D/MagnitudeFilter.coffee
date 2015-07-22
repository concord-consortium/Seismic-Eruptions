###
MagnitudeFilter - a class to receive a bunch of earthquakes, and pass on the ones that are greater
than a specified magnitude

See DateFilter's header comment for more info on filters.
###

NNode = require("./NNode")
CacheFilter = require("./CacheFilter")
MagnitudeFilterController = require("./MagnitudeFilterController")

module.exports = new
class DateFilter extends NNode
  constructor: ()->
    super

    # Rig up a controller
    @controller = MagnitudeFilterController

    @minMagnitude = -Infinity
    @maxMagnitude = Infinity

    @controller.subscribe "update", (updatedFilter) =>
      # Shim so I can write less code
      updatedFilter.maxMagnitude = Infinity

      # Event when the controller has updated parameters.
      if updatedFilter.minMagnitude > @minMagnitude or updatedFilter.maxMagnitude < @maxMagnitude

        # Filter region has shrunk, thus data may be invalid

        @post "flush", @filterMagnitudes(@cachedData, updatedFilter.minMagnitude,
          updatedFilter.maxMagnitude)

      else
        # Filter region has grown
        # Create an array to be filled with additional data points
        additionalPoints = []

        # Append to that array all new points on (possibly) both ends of the new range
        @filterMagnitudes @cachedData, updatedFilter.minMagnitude, @minMagnitude, additionalPoints
        @filterMagnitudes @cachedData, @maxMagnitude, updatedFilter.maxMagnitude, additionalPoints

        # Stream the new data to the further filters
        @post "stream", additionalPoints if additionalPoints.length > 0

      # Update current filter state
      @minMagnitude = updatedFilter.minMagnitude
      @maxMagnitude = updatedFilter.maxMagnitude

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
      @post "stream", @filterMagnitudes(newData, @minMagnitude, @maxMagnitude)

    @inputNode.subscribe "flush", (freshData)=>
      # Incoming data has changed in a way that the current cache
      # is out of date, and may contain points irrelevant to the stream. Thus, purge the cache
      # and refill with fresh data. Also, refill the next filter with fresh data too.
      @cachedData = freshData
      @post "flush", @filterMagnitudes(@cachedData, @minMagnitude, @maxMagnitude)

    @inputNode.tell "request-update"
  ###
  Creates a new array and fills it with the dataset, diced with given parameters
  Note: minMagnitude is inclusive, maxMagnitude is exclusive
  ###
  filterMagnitudes: (data, minMagnitude, maxMagnitude, newArray = [])->
    # NOTE: This is where the filter MAGIC happens
    for point in data
      if minMagnitude <= point.properties.mag < maxMagnitude
        newArray.push(point)
    return newArray
