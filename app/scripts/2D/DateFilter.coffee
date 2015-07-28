###
DateFilter - a class to receive a bunch of earthquakes, and pass on the ones that lie in between
the set date ranges.

Before we begin, let's get a visual picture of what's going on here.

## FILTER DATA FLOW DIAGRAM ##

+---------------------------------+
| Another node that is our input  |
+---------------------------------+
   inputNode     ||            ^ inputNode
   .subscribe()  \/            | .tell()
+---------------------------------+
| * The filter in consideration * |
+---------------------------------+
         @post() ||            ^ @listen()
                 \/            |
+---------------------------------+
| Another node that is our output |
+---------------------------------+

The majority of data (the general data flow) is shown by the thick arrows in the center.
The control flow follows the thinner arrows on the right.
NOTE that the listed methods pertain to the filter in consideration, which is our current class.

## FILTER OPERATIONS OVERVIEW ##

A filter is a device designed to take some input and remove something from it to provide as output.
In this case, we're removing earthquakes that don't fall within a date range.

Now, these fliters are designed with the web in mind. They're designed to be asynchonous and accept
data points in chunks as they arrive over a web connection. This chunk-based data flow I will call
streaming. Streaming does has a downside though. Because data flows around in chunks, it can be hard
to get a grand picture of what the entire data set looks like at a given time, say, to plot all the
points that have arrived thus far. As such, each filter has a cache. Each time a chunk (which should
contain new data points only) gets sent to the filter, those points are added to the cache.

Now why did I choose to use a per-filter cache? Why not one at the very end of the filter chain?
It's because I figured we'd need to deal with changing filter parameters. Every time a filter's
parameters change, it may output different information. For example, let's say that the date range
was expanded by the user, from 1900-1950 to 1900-2000. That just added 50 years of earthquake
points to our filter's output. All that needs to be done in this case is to send a chunk
of earthquakes from 1950-2000 to the subsequent filter, and it's good to go, the same way as if it
were to receive a new set of data from the web. This new data will propagate down the chain and
eventually reflect in the map.

However, let's use the flipside of that example and say that the date range was contracted from
1900-2000 back to 1900-1950. Now the points between 1950-2000 residing in the subsequent filter's
cache are invalid, and don't pertain to our current filter parameters. They need to be removed
somehow. The efficient option would be to inform the filter that these points are invalid,
completing a diff-like system, but I've opted for a less efficient but easier to code method of
completely clearing the subsequent filter's cache, then refilling it manually with data that
passes the current filter. I deem this process flushing.

That just about sums up the mechanics of the filter.
###

NNode = require("./NNode")
MagnitudeFilter = require("./MagnitudeFilter")
DateFilterController = require("./DateFilterController")

module.exports = new
class DateFilter extends NNode
  constructor: ()->
    super

    # Rig up a controller
    @controller = DateFilterController

    @startDate = -Infinity
    @endDate = Infinity

    @controller.subscribe "update", (updatedFilter) =>
      # Event when the controller has updated parameters.
      if updatedFilter.startDate > @startDate or updatedFilter.endDate < @endDate

        # Filter region has shrunk, thus data may be invalid

        @post "flush", @filterDates(@cachedData, updatedFilter.startDate, updatedFilter.endDate)

      else
        # Filter region has grown
        # Create an array to be filled with additional data points
        additionalPoints = []

        # Append to that array all new points on (possibly) both ends of the new range
        @filterDates @cachedData, updatedFilter.startDate, @startDate, additionalPoints
        @filterDates @cachedData, @endDate, updatedFilter.endDate, additionalPoints

        # Stream the new data to the further filters
        @post "stream", additionalPoints if additionalPoints.length > 0

      # Update current filter state
      @startDate = updatedFilter.startDate
      @endDate = updatedFilter.endDate

    # Here's where all the data that enters the filter will be stored.
    @cachedData = []

    # Rig up the source filter
    @inputNode = MagnitudeFilter

    @inputNode.subscribe "stream", (newData)=>
      # Event upon incrementally receiving a new data chunk from the source

      # First, cache it up!
      for point in newData
        @cachedData.push(point)

      # Then, stream it on!
      @post "stream", @filterDates(newData, @startDate, @endDate)

    @inputNode.subscribe "flush", (freshData)=>
      # Incoming data has changed in a way that the current cache
      # is out of date, and may contain points irrelevant to the stream. Thus, purge the cache
      # and refill with fresh data. Also, refill the next filter with fresh data too.
      @cachedData = freshData
      @post "flush", @filterDates(@cachedData, @startDate, @endDate)

  ###
  Creates a new array and fills it with the dataset, diced with given parameters
  Note: startDate is inclusive, endDate is exclusive
  ###
  filterDates: (data, startDate, endDate, newArray = [])->
    # NOTE: This is where the filter MAGIC happens
    for point in data
      if startDate <= point.properties.time < endDate
        newArray.push(point)
    return newArray
