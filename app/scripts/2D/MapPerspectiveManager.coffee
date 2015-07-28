###
Manages the map's movement (pan and zoom)
###

NNode = require("./NNode")
MapView = require("./MapView")
SessionController = require("./SessionController")

module.exports = new
class MapPerspectiveManager extends NNode
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

    @sessionController.subscribe "update", (updates)=>
      needsUpdating = no
      if "minLatitude" of updates
        {@minLatitude} = updates
        needsUpdating = yes
      if "maxLatitude" of updates
        {@maxLatitude} = updates
        needsUpdating = yes
      if "minLongitude" of updates
        {@minLongitude} = updates
        needsUpdating = yes
      if "maxLongitude" of updates
        {@maxLongitude} = updates
        needsUpdating = yes
      if "restrictedView" of updates
        {@restrictedView} = updates
        needsUpdating = yes
      if needsUpdating
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

    bounds = L.latLngBounds(
      L.latLng(@minLatitude, @minLongitude),
      L.latLng(@maxLatitude, @maxLongitude)
    )

    @mapView.tell "set-bounds", bounds

    if @restrictedView
      @mapView.tell "freeze", bounds

    @previouslyRestrictedView = @restrictedView
