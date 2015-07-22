###
CacheFilter - a class to receive data from the web and cache it all up, and serve it to the filters
that come after.

TODO: FIXME: HACK: NOTE: THIS CLASS IS HALF-BAKED at the moment
###

NNode = require("./NNode")

module.exports = new
class CacheFilter extends NNode
  constructor: ()->
    super

    # HACK: Don't cry, this is temporary
    # Just try to not let it all out when reading the next few lines
    setTimeout ()=>
      # I called it the seed because it's supposed to be the core that exists before
      # more earthquakes spawn
      # But really, this should be attached by two Providers in the future. See the flowchart.
      $.ajax("earthquakeSeed.json").done (data)=>
        @post "stream", data.features
    , 200
