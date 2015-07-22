###
A class to manage the boundaries toggle switch
###

NNode = require("./NNode")

module.exports = new
class BoundariesToggleUI extends NNode
  constructor: ()->
    super
    # Same hack as PlaybackSliderUI
    preventChangeFromHappenningHack = no

    @plateToggle = $("#plate-toggle")
    @plateToggle.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update", @plateToggle.parent().hasClass("ui-flipswitch-active")

    @listen "set", (value)=>
      preventChangeFromHappenningHack = yes
      if value
        @plateToggle.parent().addClass("ui-flipswitch-active")
      else
        @plateToggle.parent().removeClass("ui-flipswitch-active")
      preventChangeFromHappenningHack = no
