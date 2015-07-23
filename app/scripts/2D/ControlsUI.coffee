###
Represents the two show/hide chevron buttons
###

NNode = require("./NNode")

module.exports = new
class App extends NNode
  constructor: ()->
    super
    # Get those buttons
    @showButton = $("#show-controls")
    @hideButton = $("#hide-controls")

    # We don't discriminate - any button press'll send an update message

    @showButton.add(@hideButton).click ()=>
      @post "update"
