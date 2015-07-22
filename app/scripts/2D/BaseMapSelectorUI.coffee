###
A class to manage the base map selector
###

NNode = require("./NNode")

module.exports = new
class BaseMapSelectorUI extends NNode
  constructor: ()->
    super
    # Same hack as PlaybackSliderUI
    preventChangeFromHappenningHack = no

    @baseMapSelector = $("#base-map-selector")
    @baseMapSelector.on "change", ()=>
      unless preventChangeFromHappenningHack
        @post "update", @baseMapSelector.val()

    @listen "set", (value)=>
      preventChangeFromHappenningHack = yes
      @baseMapSelector.val(value).selectmenu("refresh")
      preventChangeFromHappenningHack = no
