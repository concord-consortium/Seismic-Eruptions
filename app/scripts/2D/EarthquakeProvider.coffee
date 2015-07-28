###
A class to load in earthquake data
###

NNode = require("./NNode")
SessionController = require("./SessionController")

module.exports = new
class EarthquakeProvider extends NNode

  constructor: ()->
    super
    @sessionController = SessionController

    # The datasets that have already been loaded. Don't want to be making duplicate requests, do we?
    @cachedDatasets = []

    # The requested datasets
    @datasets = []

    $(document).ready ()=>
      @loadDatasets()

    @sessionController.subscribe "update", (updates)=>
      if "datasets" of updates
        {@datasets} = updates
        @loadDatasets()

    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @datasets
    }

  # Loads in the datasets, unless they are already loaded
  loadDatasets: ()->
    for dataSetURL in @datasets
      @cachedDatasets.push(dataSetURL)
      $.ajax(dataSetURL).error(()->
        # Oh noes! The dataset didn't load!
      ).done (data)=>
        # Delicious data. Pass it on.
        @post "stream", data.features
