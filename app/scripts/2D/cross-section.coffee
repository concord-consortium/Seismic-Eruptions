CustomPolyline = require '2D/extensions/custom-polyline'

class CrossSection
  width: 1.5  # width in degrees
  lineOptions:
    stroke: true
    color: '#ff0000'
    weight: 4
    opacity: 0.5
    fill: false
    clickable: true

  points: []

  _featureGroup: null
  _line: null
  _rect: null

  constructor: (@map) ->
    @_featureGroup = new L.LayerGroup()
    @_editMarkerGroup = new L.LayerGroup()
    @map.addLayer(@_featureGroup)
    @map.addLayer(@_editMarkerGroup)

    polyline = new CustomPolyline @map
    polyline.enable()

    @_line = new L.Polyline([], @lineOptions)
    @_rect = new L.polygon([])

    @map.on 'draw:created', (e)=> @handleCreate(e)

  handleCreate: (e) ->
    [p0,p1] = e.layer.getLatLngs()

    @_updateLine p0, p1
    @_updateRect p0, p1
    @_createEditControls()

    @map.fitBounds(@_rect.getBounds()) if @_rect?

  _updateLine: (p0, p1) ->
    @_line.setLatLngs([p0,p1])

    if !@_featureGroup.hasLayer(@_line)
      @_featureGroup.addLayer(@_line)
    @_line

  _updateRect: (p0, p1) ->
    # figure out our vertices in pixels
    c0 = @map.latLngToContainerPoint p0
    c1 = @map.latLngToContainerPoint p1

    dir = @_direction(c0,c1)

    # calculate the differences (in lat/lng)  (not projected - it won't give the same actual width at the equator as at the poles, but it'll be close enough)
    dLng = @width * Math.cos(dir+Math.PI/2)
    dLat = @width * Math.sin(dir+Math.PI/2)

    # now figure out the distances in pixels
    n0 = L.latLng(p0.lat + dLat, p0.lng + dLng)
    c3 = @map.latLngToContainerPoint(n0)

    distance = c0.distanceTo(c3)

    dx = distance * Math.cos(dir+Math.PI/2) # in pixels
    dy = distance * Math.sin(dir+Math.PI/2) # in pixels

    # calculate our 4 corners in pixels
    r0 = c0.add L.point(dx,dy)
    r1 = c0.add L.point(-dx,-dy)
    r2 = c1.add L.point(-dx,-dy)
    r3 = c1.add L.point(dx,dy)

    # now create our rectangle, converting to lat/lng
    @points = [@map.containerPointToLatLng(r0), @map.containerPointToLatLng(r1), @map.containerPointToLatLng(r2), @map.containerPointToLatLng(r3)]
    @_rect.setLatLngs(@points)

    if !@_featureGroup.hasLayer(@_rect)
      @_featureGroup.addLayer(@_rect)
    @_rect

  _direction: (p0, p1) ->
    return Math.atan2 (p1.y - p0.y), (p1.x - p0.x)

  _midPoint: (p0, p1) ->
    dx = p1.lng - p0.lng
    dy = p1.lat - p0.lat

    return L.latLng(p0.lat + (dy/2), p0.lng + (dx/2))

  _createEditControls: ->
    # Left location control
    leftControl = @_createEditMarker @_line.getLatLngs()[0], (e) =>
      @_updateLine(e.target.getLatLng(), @_line.getLatLngs()[1])
      @_updateRect(e.target.getLatLng(), @_line.getLatLngs()[1])
      centerControl.updateLocation @_rect.getBounds().getCenter()
      resizeControl.updateLocation @_midPoint(@_rect.getLatLngs()[0], @_rect.getLatLngs()[3])
    # Right location control
    rightControl = @_createEditMarker @_line.getLatLngs()[1], (e) =>
      @_updateLine(@_line.getLatLngs()[0], e.target.getLatLng())
      @_updateRect(@_line.getLatLngs()[0], e.target.getLatLng())
      centerControl.updateLocation @_rect.getBounds().getCenter()
      resizeControl.updateLocation @_midPoint(@_rect.getLatLngs()[0], @_rect.getLatLngs()[3])
    # Center move control
    centerControl = @_createEditMarker @_midPoint(@_line.getLatLngs()...), (e) =>
      # Translate the rectangle and line by the distance moved
      newLatLng = e.target.getLatLng()

      dx = newLatLng.lng - centerControl._origLatLng.lng
      dy = newLatLng.lat - centerControl._origLatLng.lat

      [p0, p1] = @_line.getLatLngs()
      p0.lat += dy
      p0.lng += dx

      p1.lat += dy
      p1.lng += dx

      @_updateLine(p0, p1)
      @_updateRect(p0, p1)

      leftControl.updateLocation p0
      rightControl.updateLocation p1

      p3 = resizeControl.getLatLng()
      p3.lat += dy
      p3.lng += dx
      resizeControl.setLatLng p3

      centerControl._origLatLng = newLatLng

    # Top resize width control
    resizeControl = @_createEditMarker @_midPoint(@_rect.getLatLngs()[0], @_rect.getLatLngs()[3]), (e) =>
      myLoc = e.target.getLatLng()
      centerLoc = centerControl.getLatLng()
      [p1,p2] = @_line.getLatLngs()

      # if we can guarantee the control point to be on a line perpendicular to @_line, then the following works:
      #   @width = Math.sqrt(Math.pow(myLoc.lng - centerLoc.lng, 2) + Math.pow(myLoc.lat - centerLoc.lat, 2))
      # Otherwise, calculate the distance from the control to any point on @_line:
      numer = Math.abs((p2.lat - p1.lat)*myLoc.lng - (p2.lng - p1.lng)*myLoc.lat + p2.lng*p1.lat - p2.lat*p1.lng)
      denom = Math.sqrt(Math.pow(p2.lng - p1.lng, 2) + Math.pow(p2.lat - p1.lat, 2))
      @width = numer/denom

      console.log("new width: ", @width, e.target.getLatLng(), centerControl.getLatLng())

      @_updateLine(@_line.getLatLngs()...)
      @_updateRect(@_line.getLatLngs()...)

  _createEditMarker: (latlng, onDrag) ->
    editMarker = new L.Marker latlng,
      draggable: true
      icon: new L.DivIcon
        iconSize: new L.Point(8, 8)
        className: 'leaflet-div-icon leaflet-editing-icon'

    editMarker._origLatLng = latlng
    editMarker.updateLocation = (latLng) ->
      @_origLatLng = latLng
      @setLatLng latLng

    editMarker.on('drag', onDrag)
    editMarker.on('dragend', onDrag)

    @_editMarkerGroup.addLayer(editMarker)

    return editMarker

module.exports = CrossSection
