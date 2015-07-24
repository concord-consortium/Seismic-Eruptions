###
A class to watch for hash changes and update the map accordingly
NOTE: Probably decouple the share link going forward,
as well as find a better way to load in hashes...
###
NNode = require("./NNode")
SessionController = require("./SessionController")

module.exports = new
class HashController extends NNode
  constructor: ()->
    super
    @sessionController = SessionController

    @delayedTimer = null
    @lastUpdate = null
    @sessionController.subscribe "append", (session)=>
      # Defer rapid update events to a maximum of 1.5 seconds
      if @delayedTimer?
        clearTimeout @delayedTimer
        @delayedTimer = null
      if @lastUpdate? and Date.now() - @lastUpdate < 1500
        # Improve this?
        @delayedTimer = setTimeout ()=>
          @updateLink(session)
        , 300
      else
        @updateLink(session)

    $(window).on "load", ()=>
      # find a better way to load hashes?
      try
        @sessionController.tell "replace-and-update",
          JSON.parse(window.decodeURIComponent(window.location.hash[1...]))
      catch error

      # Force a url update
      @sessionController.tell "append", {}

  updateLink: (session)->
    window.location.hash = "##{window.encodeURIComponent(JSON.stringify(session))}"
    $("#share-link").val("#{window.location}")
    @lastUpdate = Date.now()
