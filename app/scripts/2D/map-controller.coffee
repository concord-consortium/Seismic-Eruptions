class MapController
  constructor: (@map)->
    @map.controller = @
    @util = require 'common/util'
    @initController()

  # timeline of events
  timeLine: null

  # speed of events
  speed: 6

  # sound of the audio
  snd: new Audio("tap.wav") # buffers automatically when created

  _getDepth: (feature) ->
    try
      return feature.geometry.geometries[0].coordinates[2]
    catch e
      undefined
    try
      return feature.geometry.coordinates[2]
    catch e
      undefined
    console.log('Failed to find depth!', feature)
    return '???'

  _getCurrentLimit: (zoom, tileSize) ->
    numTiles = Math.pow(2, zoom)
    if zoom is 0
      return 15000
    else if zoom <= 3
      return Math.floor(20000 / Math.pow(numTiles,2))

    # Figure out how many tiles are actually displaying, and limit based on that
    bounds = @map.leafletMap.getBounds()
    nw = bounds.getNorthWest()
    se = bounds.getSouthEast()
    nwPixel = @map.leafletMap.project(nw)
    sePixel = @map.leafletMap.project(se)
    nwTile = nwPixel.divideBy(tileSize)
    seTile = sePixel.divideBy(tileSize)
    left = Math.floor(nwTile.x)
    right = Math.floor(seTile.x)
    top = Math.floor(nwTile.y)
    bottom = Math.floor(seTile.y)

    # Factor in world wrapping
    if left > right
      left = left - numTiles

    if top > bottom
      top = top - numTiles

    width = right - left
    height = bottom - top

    return Math.floor(15000/(width*height))

  _getCurrentMag: (zoom) ->
    mag = @_getDesiredMag(zoom)
    @map.parameters.mag = mag
    return mag

  _getDesiredMag: (zoom) ->
    return @map.parameters.desiredMag if @map.parameters.desiredMag?
    return 2 if (zoom > 8)
    return 3 if (zoom > 6)
    return 4 if (zoom > 3)
    return 5 if (zoom > 1)
    return 6

  _geojsonURL: (tileInfo) ->
    tileSize = tileInfo.tileSize
    tilePoint = L.point(tileInfo.x, tileInfo.y)
    nwPoint = tilePoint.multiplyBy(tileSize)
    sePoint = nwPoint.add(new L.Point(tileSize, tileSize))
    nw = @map.leafletMap.unproject(nwPoint)
    se = @map.leafletMap.unproject(sePoint)
    zoom = tileInfo.z

    url = '&limit=' + @_getCurrentLimit(zoom, tileSize) +
             '&minmagnitude=' + @_getCurrentMag(zoom) +
             '&minlatitude=' + se.lat +
             '&maxlatitude=' + nw.lat +
             '&minlongitude=' + nw.lng +
             '&maxlongitude=' + se.lng +
             '&starttime=' + @map.parameters.startdate +
             '&endtime=' + @map.parameters.enddate +
             '&callback=' + tileInfo.requestId
    return url

  _updateSlider: ->
    $("#slider").slider("value", (@timeLine.progress() * @map.values.timediff))
    $("#date").html(util.timeConverter((@timeLine.progress() * @map.values.timediff) + @map.parameters.starttime))

  initController: ->
    #  colour gradient generator
    @rainbow = new Rainbow()
    @rainbow.setNumberRange(0, 700)

    @timeLine = new TimelineLite({
      onUpdate: => @_updateSlider()
    })

    style = {
      "clickable": true
      "color": "#000"
      "fillColor": "#00D"
      weight: 1
      opacity: 1
      fillOpacity: 0.3
    }
    hoverStyle = {
      "fillOpacity": 1.0
    }
    unhoverStyle = {
      "fillOpacity": 0.3
    }

    geojsonTileLayer = new L.TileLayer.GeoJSONP('http://comcat.cr.usgs.gov/fdsnws/event/1/query?eventtype=earthquake&orderby=time&format=geojson{url_params}',
      {
        url_params: (tileInfo) => @_geojsonURL(tileInfo),
        clipTiles: false,
        wrapPoints: false
      }, {
        pointToLayer: (feature, latlng) ->
          return L.circleMarker(latlng, style)
        style: style
        onEachFeature: (feature, layer) =>
          depth = @_getDepth(feature)
          layer.setStyle({
            radius: feature.properties.mag,
            fillColor: "#" + @rainbow.colourAt(depth)
          })
          if feature.properties?
            layer.bindPopup("Place: <b>" + feature.properties.place + "</b></br>Magnitude : <b>" + feature.properties.mag + "</b></br>Time : " + @util.timeConverter(feature.properties.time) + "</br>Depth : " + depth + " km")
          if !(layer instanceof L.Point)
            layer.on 'mouseover', ->
              layer.setStyle(hoverStyle)
            layer.on 'mouseout', ->
              layer.setStyle(unhoverStyle)
      }
    )

    spinnerOpts = {
      lines: 13
      length: 10
      width: 7
      radius: 10
      top: '37px'
      left: '70px'
      color: '#cccccc'
      shadow: true
    }

    geojsonTileLayer.on 'loading', (event) =>
      @map.leafletMap.spin(true, spinnerOpts)

    geojsonTileLayer.on 'load', (event) =>
      @map.leafletMap.spin(false)

    geojsonTileLayer.addTo(@map.leafletMap)

module.exports = MapController
