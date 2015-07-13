DataLoader = require('common/data-loader')

class MapController
  @EARTHQUAKE_NUM_LIMIT: 500
  constructor: (@map)->
    @map.controller = @
    @util = require 'common/util'
    @values = {}

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
    return MapController.EARTHQUAKE_NUM_LIMIT

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

    return Math.floor(15000 / (width * height))

  _getCurrentMag: (zoom) ->
    mag = @_getDesiredMag(zoom)
    if @map.parameters.mag isnt mag
      @map.parameters.mag = mag
      $('#magnitude-slider').val(mag).slider('refresh')
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
      bounds = @map.leafletMap.getBounds()
      if @map.parameters.nw?
        nw = @map.parameters.nw
      else if @map.parameters.center? and @map.parameters.zoom?
        nw = bounds.getNorthWest()

      if @map.parameters.se?
        se = @map.parameters.se
      else if @map.parameters.center? and @map.parameters.zoom?
        se = bounds.getSouthEast()
      tileSize = 256
      zoom = 0

    url = "&limit=#{@_getCurrentLimit(zoom, tileSize)}\
           &jsonerror=true\
           &minmagnitude=#{@_getCurrentMag(zoom)}\
           &starttime=#{@map.parameters.startdate}\
           &endtime=#{@map.parameters.enddate}"
    if nw? and se?
      url += "&minlatitude=#{se.lat}\
              &maxlatitude=#{nw.lat}\
              &minlongitude=#{nw.lng}\
              &maxlongitude=#{se.lng}"

    return url

  _updateSlider: ->
    $("#slider").val(Math.ceil(@timeLine.progress() * @map.values.timediff)).slider('refresh')
    $("#date").html(@util.timeConverter((@timeLine.progress() * @map.values.timediff) +
      @map.parameters.starttime))

  _markerStyle:
    clickable: true
    color: "#000"
    fillColor: "#00D"
    weight: 1
    opacity: 1
    fillOpacity: 0.3

  _markerCreator: ->
    pointToLayer: (feature, latlng) =>
      return L.circleMarker(latlng, @_markerStyle)
    style: @_markerStyle
    onEachFeature: (feature, layer) =>
      depth = @_getDepth(feature)
      layer.setStyle({
        radius: 0.9 * Math.pow(1.5, (feature.properties.mag - 1)),
        fillColor: "#" + @rainbow.colourAt(depth)
      })
      if feature.properties?
        layer.bindPopup("\
        Place: <b>#{feature.properties.place}</b></br>\
        Magnitude: <b> #{feature.properties.mag}</b></br>\
        Time: #{@util.timeConverter(feature.properties.time)}</br>\
        Depth: #{depth} km")
      if !(layer instanceof L.Point)
        layer.on 'mouseover', ->
          layer.setStyle
            fillOpacity: 1.0
        layer.on 'mouseout', ->
          layer.setStyle
            fillOpacity: 0.3

  initController: ->
    #  colour gradient generator
    @rainbow = new Rainbow()
    @rainbow.setNumberRange(0, 700)

    @timeLine = new TimelineLite
      onUpdate: => @_updateSlider()

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
      @_loadStaticData(spinnerOpts)
    else
      @geojsonTileLayer = new L.TileLayer.GeoJSON('http://earthquake.usgs.gov/fdsnws/event/1/query?\
        eventtype=earthquake&orderby=magnitude&format=geojson{url_params}',
        {
          url_params: (tileInfo) => @_geojsonURL(tileInfo),
          clipTiles: false,
          wrapPoints: false
        }, @_markerCreator()
      )
      @geojsonTileLayer.on 'loading', (event) =>
        @map.leafletMap.spin(true, spinnerOpts)

      @geojsonTileLayer.on 'load', (event) =>
        @map.leafletMap.spin(false)

      @geojsonTileLayer.addTo(@map.leafletMap)

  reloadData: ->
    if @map.parameters.timeline
      # Clear the old points, request the new ones
      @timeLine.pause()
      for circle in @map.earthquakes.circles
        @map.leafletMap.removeLayer(circle) if @map.leafletMap.hasLayer(circle)
      @map.earthquakes.circles = []
      @map.earthquakes.time = []
      @map.earthquakes.depth = []
      @_loadStaticData()
    else
      @geojsonTileLayer.redraw()

  _loadStaticData: (spinnerOpts) ->
    @timeLine.pause()
    loader = new DataLoader()
    if @map.parameters.data?
      promise = loader.load(@map.parameters.data, {ajax: true})
    else if @map.parameters.datap? and @map.parameters.datap_callback?
      promise = loader.load(@map.parameters.datap, {callback: @map.parameters.datap_callback})
    else
      promise = loader.load("http://earthquake.usgs.gov/fdsnws/event/1/query?\
        eventtype=earthquake&orderby=time-asc&format=geojson#{@_geojsonURL()}", {ajax: true})
    promise.then (results) =>
      @map.values.size = results.features.length

      for feature, i in results.features
        @map.earthquakes.circles[i] = L.geoJson feature, @_markerCreator()
        @map.earthquakes.time[i] = feature.properties.time
        @map.earthquakes.depth[i] = feature.geometry.coordinates[2]

        # add events to timeline
        delay = if i is 0 then 0 else
          20 * ((feature.properties.time - results.features[i - 1].properties.time) / 1000000000)
        @timeLine.append(TweenLite.delayedCall(delay, ((i)=> @map.mapAdder(i)), [i.toString()]))

      if @map.values.size > 0
        @map.values.timediff = results.features[@map.values.size - 1].properties.time -
          results.features[0].properties.time
        @map.parameters.starttime = results.features[0].properties.time

        $('#slider-wrapper').html "<input id='slider' name='slider' type='range' min='0'
          max='#{@map.values.timediff}' value='0'step='1' style='display: none;'
          data-theme='a' data-track-theme='a'>"
        $("#slider").slider
          slidestart: (event) =>
            @timeLine.pause()
          slidestop: (event) =>
            $("#date").html(@util.timeConverter(@map.parameters.starttime))
            @timeLine.progress($("#slider").val() / (@map.values.timediff))

        $("#info").html """<p>
          total earthquakes: #{@map.values.size}<br/>
          minimum depth: #{Math.min.apply(null, @map.earthquakes.depth)} km</br>
          maximum depth: #{Math.max.apply(null, @map.earthquakes.depth)} km
          </p>
          <div class='ui-body ui-body-a'><p>
            <a href='http://github.com/gizmoabhinav/Seismic-Eruptions'>Link to the project</a>
          </p></div>
        """
        $("#startdate").html("Start date: #{@util.timeConverter(@map.parameters.startdate)}")
        $("#enddate").html("End date: #{@util.timeConverter(@map.parameters.enddate)}")
        $("#magcutoff").html("Cutoff magnitude: #{@map.parameters.mag}")

        @timeLine.resume()

module.exports = MapController
