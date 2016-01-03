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
    @loadedHack = false
    @sessionController.subscribe "append", (session)=>
      return if not @loadedHack
      @updateLink(session)

    $(window).on "hashchange", ()=>
      @manageHashChange()

    $(window).on "load", ()=>
      @loadedHack = true
      @manageHashChange()

  manageHashChange: ()->
    try
      @sessionController.tell "replace-and-update",
        JSON.parse(window.decodeURIComponent(window.location.hash[1...]))
    catch error
      @loadDefaults()

  loadDefaults: ()->
    @sessionController.tell "replace-and-update", {scaffold: "regions/world.json"}

  updateLink: (session)->
    encodedSession = "##{window.encodeURIComponent(JSON.stringify(session))}"
    $("#share-link").val("#{window.location.origin}#{window.location.pathname}#{encodedSession}")
    # Keep only scaffold URL in the hash, so user can use browser's back button to navigate between regions.
    window.location.hash = "##{window.encodeURIComponent(JSON.stringify({scaffold: session.scaffold}))}"
