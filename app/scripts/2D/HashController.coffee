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
    @lastHash = null # To detect when the hash changes

    @loadedHack = false
    @sessionController.subscribe "append", (session)=>
      return if not @loadedHack
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

    $(window).on "hashchange", ()=>
      @manageHashChange()

    $(window).on "load", ()=>
      # Start listening for events after load
      @loadedHack = true
      @manageHashChange()

  manageHashChange: ()->
    if @lastHash isnt window.location.hash
      if @isScaffoldHash(window.location.hash)
        @post "scaffold-update", window.location.hash[10...]
        # Force update of url
        @sessionController.tell "append", {}
      else
        # find a better way to load hashes?
        try
          @sessionController.tell "replace-and-update",
            JSON.parse(window.decodeURIComponent(window.location.hash[1...]))
        catch error
          @loadDefaults()
        # Force an update of the url
        @sessionController.tell "append", {}
      @lastHash = window.location.hash

  loadDefaults: ()->
    console.log("defaults")
    @post "scaffold-update", "regions/world.json"

  updateLink: (session)->
    window.location.hash = @lastHash = "##{window.encodeURIComponent(JSON.stringify(session))}"
    $("#share-link").val("#{window.location}")
    @lastUpdate = Date.now()

  # Returns whether or not the given hash is a scaffold reference
  isScaffoldHash: (hash)->
    return hash?.startsWith("#scaffold:")
