###
A class to manage scaffolding
Loads in the scaffold geo json from a URL.
Here are some example properties the json will have (all are optional except for type and features)
{
  "currentDatasets":[
    "datasets/world.json"
  ],
  "minMagnitude":5,
  "startDate":-315601200000,
  "animatedEndDate":1438098194377, # The current value of the playback slider
  "endDate":1438098194377, # This a date represented as an integer
  "boundariesVisible":false,
  "baseLayer":"satellite", # Can be satellite, street, or density
  "controlsVisible":true,
  "keyVisible":false,
  "minLatitude":-40, # Defines the view of the map
  "minLongitude":-50, # Defines the view of the map
  "maxLatitude":40, # Defines the view of the map
  "maxLongitude":50, # Defines the view of the map
  "restrictedView":false, # Whether or not the user will be able to pan/zoom
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {},
      "geometry": {
        # ... stuff. Use a geojson generator to populate this
      }
    },
  ]
}

###

NNode = require("./NNode")
SessionController = require("./SessionController")
HashController = require("./HashController")
module.exports = new
class ScaffoldController extends NNode

  constructor: ()->
    super
    @sessionController = SessionController

    @hashController = HashController

    @scaffold = ""

    # A quick and tiny update
    @sessionController.subscribe "update", (updates)=>
      # Only update if the scaffold is the only one being updated
      if "scaffold" of updates
        {@scaffold} = updates
        @updateScaffold()

    @updateScaffold()
    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @scaffold
    }

  # If alsoUpdateSession is true, completely updates the session to scaffold defaults
  # Otherwise just draw a pretty scaffold on the map
  updateScaffold: (alsoUpdateSession = true)->
    # TODO: Add caching or something
    if @scaffold.length > 0
      $.ajax(@scaffold).done (data)=>
        # Send the data to the scaffold layer manager
        @post "update", data

        if alsoUpdateSession
          # Update everything else about the session
          @sessionController.tell "replace-and-update", data
