class MapLimits
  constructor: ->
    @util = require 'common/util'
    @latlng =
      x1: @util.getURLParameter("x1")
      x2: @util.getURLParameter("x2")
      x3: @util.getURLParameter("x3")
      x4: @util.getURLParameter("x4")

      y1: @util.getURLParameter("y1")
      y2: @util.getURLParameter("y2")
      y3: @util.getURLParameter("y3")
      y4: @util.getURLParameter("y4")

    @coords =
      x1: @util.convertCoordinatesx(@latlng.x1)
      y1: @util.convertCoordinatesy(@latlng.y1)

      x2: @util.convertCoordinatesx(@latlng.x2)
      y2: @util.convertCoordinatesy(@latlng.y2)

      x3: @util.convertCoordinatesx(@latlng.x3)
      y3: @util.convertCoordinatesy(@latlng.y3)

      x4: @util.convertCoordinatesx(@latlng.x4)
      y4: @util.convertCoordinatesy(@latlng.y4)

    @coords.minx = Math.min(@coords.x1,@coords.x2,@coords.x3,@coords.x4)
    @coords.miny = Math.min(@coords.y1,@coords.y2,@coords.y3,@coords.y4)
    @coords.maxx = Math.max(@coords.x1,@coords.x2,@coords.x3,@coords.x4)
    @coords.maxy = Math.max(@coords.y1,@coords.y2,@coords.y3,@coords.y4)

    if (3-Math.ceil(@coords.maxx-@coords.minx)) >= 0 && (3-Math.ceil(@coords.maxy-@coords.miny)) >=0        # temporary limit to the size of the rectangle
      @coords.leftTileLimit = Math.floor(@coords.minx-(3-Math.ceil(@coords.maxx-@coords.minx)))
      @coords.topTileLimit  = Math.floor(@coords.miny-(3-Math.ceil(@coords.maxy-@coords.miny)))
    else
      @coords.leftTileLimit = Math.floor(@coords.minx)
      @coords.topTileLimit  = Math.floor(@coords.miny)

    @coords.midx = ((@coords.maxx+@coords.minx)/2)
    @coords.midy = ((@coords.maxy+@coords.miny)/2)

module.exports = new MapLimits()
