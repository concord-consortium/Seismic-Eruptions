###
An all-in-one class to manage the map key, populating it as well as showing/hiding it.
Could perhaps be split into multiple classes
###
NNode = require("./NNode")
DataFormatter = require("./DataFormatter")
MapKeyToggleUI = require("./MapKeyToggleUI")
SessionController = require("./SessionController")

module.exports = new
class MapKeyController extends NNode
  constructor: ()->
    super
    @mapKey = $("#map-key")

    # Populate the keys
    @mapKey.find(".magnitude-key").html(
      (for magnitude in [3..9]
        radius = DataFormatter.magnitudeToRadius(magnitude)
        """<div class="magnitude-item">
          <div class="magnitude-example" style="\
            width: #{2 * radius}px; height: #{2 * radius}px;\
            margin-left: #{-radius}px; margin-top: #{-radius}px;"></div>
          #{DataFormatter.formatMagnitude(magnitude)}
        </div>""").join(""))

    @mapKey.find(".depth-key > .labels").html(
      ("<p>#{depth} km</p>" for depth in [0..DataFormatter.MAX_DEPTH] by 100).join(""))


    @sessionController = SessionController
    @sessionController.subscribe "update", (session)=>
      {
        @keyVisible
      } = session
      @updateKeyVisibility()

    # Rig up show/hiding
    @mapKeyToggle = MapKeyToggleUI

    # Variable to hold whether hidden or not
    @keyVisible = no

    @mapKeyToggle.subscribe "update", (value)=>
      # Toggle control visibility
      @keyVisible = value
      @updateKeyVisibility()
      @updateSession()

    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @keyVisible
    }

  updateKeyVisibility: ()->
    @mapKeyToggle.tell "set", @keyVisible

    if @keyVisible
      @mapKey.finish().fadeIn(300)
    else
      @mapKey.finish().fadeOut(300)
