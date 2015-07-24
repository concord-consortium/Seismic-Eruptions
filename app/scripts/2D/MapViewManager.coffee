###
Manages the map's movement (pan and zoom)
###

NNode = require("./NNode")
MapView = require("./MapView")
SessionController = require("./SessionController")

module.exports = new
class MapViewManager extends NNode
  constructor: ()->
    super
    @sessionController = SessionController
    @minLatitude = -40
    @minLongitude = -50
    @maxLatitude = 40
    @maxLongitude = 50
    @restrictedView = false
    @previouslyRestrictedView = false

    # Rig up that map view
    @mapView = MapView

    @mapView.subscribe "loaded", ()=>
      @updateMapView()

    @mapView.subscribe "bounds-update", (bounds)=>
      min = bounds.getSouthWest()
      max = bounds.getNorthEast()
      @minLatitude = min.lat
      @maxLatitude = max.lat
      @minLongitude = min.lng
      @maxLongitude = max.lng
      @updateSession()

    @sessionController.subscribe "update", (session)=>
      {
        @minLatitude
        @maxLatitude
        @minLongitude
        @maxLongitude
        @restrictedView
      } = session
      @updateMapView()

    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @minLatitude
      @minLongitude
      @maxLatitude
      @maxLongitude
      @restrictedView
    }

  updateMapView: ()->
    if @previouslyRestrictedView
      @mapView.tell "unfreeze"

    @mapView.tell "set-bounds", L.latLngBounds(
      L.latLng(@minLatitude, @minLongitude),
      L.latLng(@maxLatitude, @maxLongitude)
    )

    if @restrictedView
      @mapView.tell "freeze"
    @previouslyRestrictedView = @restrictedView
