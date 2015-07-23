###
A class to manage the map key toggle switch
###

NNode = require("./NNode")

module.exports = new
class MapKeyToggleUI extends NNode
  constructor: ()->
    super
    # Same hack as PlaybackSliderUI
    preventChangeFromHappenningHack = no

    @mapKey = $("#map-key-toggle")
    @mapKey.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update", @mapKey.parent().hasClass("ui-flipswitch-active")

    @listen "set", (value)=>
      preventChangeFromHappenningHack = yes
      if value
        @mapKey.parent().addClass("ui-flipswitch-active")
      else
        @mapKey.parent().removeClass("ui-flipswitch-active")
      preventChangeFromHappenningHack = no
