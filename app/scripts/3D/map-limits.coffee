class MapLimits
  constructor: ->
    @util = require 'common/util'
    @x1 = @util.convertCoordinatesx(@util.getURLParameter("x1"))
    @y1 = @util.convertCoordinatesy(@util.getURLParameter("y1"))
    @x2 = @util.convertCoordinatesx(@util.getURLParameter("x2"))
    @y2 = @util.convertCoordinatesy(@util.getURLParameter("y2"))
    @x3 = @util.convertCoordinatesx(@util.getURLParameter("x3"))
    @y3 = @util.convertCoordinatesy(@util.getURLParameter("y3"))
    @x4 = @util.convertCoordinatesx(@util.getURLParameter("x4"))
    @y4 = @util.convertCoordinatesy(@util.getURLParameter("y4"))

    @minx = Math.min(@x1,@x2,@x3,@x4)
    @miny = Math.min(@y1,@y2,@y3,@y4)
    @maxx = Math.max(@x1,@x2,@x3,@x4)
    @maxy = Math.max(@y1,@y2,@y3,@y4)

    if (3-Math.ceil(@maxx-@minx)) >= 0 && (3-Math.ceil(@maxy-@miny)) >=0        # temporary limit to the size of the rectangle
      @leftTileLimit = Math.floor(@minx-(3-Math.ceil(@maxx-@minx)))
      @topTileLimit = Math.floor(@miny-(3-Math.ceil(@maxy-@miny)))
    else
      @leftTileLimit = Math.floor(@minx)
      @topTileLimit = Math.floor(@miny)

    @midx = ((@maxx+@minx)/2)
    @midy = ((@maxy+@miny)/2)

module.exports = new MapLimits()
