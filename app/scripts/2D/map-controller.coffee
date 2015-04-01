DataLoader = require('common/data-loader')

class MapController
  constructor: (@map)->
    @map.controller = @
    @util = require 'common/util'
    @values = {}
    @initController()

  values:
    timediff: 0 # the total time between the first event and the last
    size: 0 # number of earthquakes

  earthquakes:
    circles: [] # Array of earthquake markers
    time: []    # time of occurrence of corresponding earthquakes
    depth: []   # Array of depths of corresponding earthquakes

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
    if tileInfo?
      tileSize = tileInfo.tileSize
      tilePoint = L.point(tileInfo.x, tileInfo.y)
      nwPoint = tilePoint.multiplyBy(tileSize)
      sePoint = nwPoint.add(new L.Point(tileSize, tileSize))
      nw = @map.leafletMap.unproject(nwPoint)
      se = @map.leafletMap.unproject(sePoint)
      zoom = tileInfo.z
    else
      if @map.parameters.nw
        nw = @map.parameters.nw
      if @map.parameters.se
        se = @map.parameters.se
      tileSize = 256
      zoom = 0

    url = '&limit=' + @_getCurrentLimit(zoom, tileSize) +
             '&minmagnitude=' + @_getCurrentMag(zoom) +
             '&starttime=' + @map.parameters.startdate +
             '&endtime=' + @map.parameters.enddate
    if nw? and se?
      url += '&minlatitude=' + se.lat +
             '&maxlatitude=' + nw.lat +
             '&minlongitude=' + nw.lng +
             '&maxlongitude=' + se.lng
    url += '&callback=' + tileInfo.requestId if tileInfo?.requestId?
    return url

  _updateSlider: ->
    $("#slider").slider("value", (@timeLine.progress() * @map.values.timediff))
    $("#date").html(util.timeConverter((@timeLine.progress() * @map.values.timediff) + @map.parameters.starttime))

  initController: ->
    #  colour gradient generator
    @rainbow = new Rainbow()
    @rainbow.setNumberRange(0, 700)

    @timeLine = new TimelineLite
      onUpdate: => @_updateSlider()

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

    if @map.parameters.timeline
      loader = new DataLoader()
      loader.load('http://comcat.cr.usgs.gov/fdsnws/event/1/query?eventtype=earthquake&orderby=time&format=geojson' + @_geojsonURL()).then (results) =>
        @map.values.size = results.features.length

        for feature,i in results.features
          @map.earthquakes.circles[i] = L.geoJson feature,
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

            @map.earthquakes.time[i] = feature.properties.time
            @map.earthquakes.depth[i] = feature.geometry.coordinates[2]

            # add events to timeline
            delay = if i is 0 then 0 else 20 * ((feature.properties.time - results.features[i - 1].properties.time) / 1000000000)
            @timeLine.append(TweenLite.delayedCall(delay, ((i)=> @map.mapAdder(i)), [i.toString()]))

        @map.values.timediff = results.features[@map.values.size - 1].properties.time - results.features[0].properties.time
        @map.parameters.starttime = results.features[0].properties.time

        $("#slider").slider
          value: 0
          range: "min"
          min: 0
          max: @map.values.timediff
          slide: (event, ui) =>
            $("#date").html(@util.timeConverter(@map.parameters.starttime))
            @timeLine.pause()
            @timeLine.progress(ui.value / (@map.values.timediff))

        $("#info").html("</br></br>total earthquakes : " + @map.values.size + "</br>minimum depth : " + @map.values.mindepth + " km</br>maximum depth : " + @map.values.maxdepth + " km</br></br></br><div class='ui-body ui-body-a'><p><a href='http://github.com/gizmoabhinav/Seismic-Eruptions'>Link to the project</a></p></div>")
        $("#startdate").html("Start date : " + @util.timeConverter(@map.parameters.startdate))
        $("#enddate").html("End date : " + @util.timeConverter(@map.parameters.enddate))
        $("#magcutoff").html("Cutoff magnitude : " + @map.parameters.mag)
    else
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

      geojsonTileLayer.on 'loading', (event) =>
        @map.leafletMap.spin(true, spinnerOpts)

      geojsonTileLayer.on 'load', (event) =>
        @map.leafletMap.spin(false)

      geojsonTileLayer.addTo(@map.leafletMap)

module.exports = MapController
