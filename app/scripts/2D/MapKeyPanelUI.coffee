###
A class to manage the map key and it's close button
###

NNode = require("./NNode")

module.exports = new
class MapKeyPanelUI extends NNode
  constructor: ()->
    super
    @mapKeyClose = $("#map-key-close")
    @mapKeyClose.on "click", ()=>
      @post "update"
