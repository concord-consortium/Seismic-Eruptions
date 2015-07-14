NNode = require("./NNode")
PlaybackController = require("./PlaybackController")
module.exports =
class App extends NNode
  constructor: ()->
    super
    controller = new PlaybackController()
    controller.listen "playback-update", (progress)->
      console.log(progress)
