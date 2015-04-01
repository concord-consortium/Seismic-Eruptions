CrossSection = require '2D/cross-section'
util = require 'common/util'

# The map object with all the variables of current map being shown
class Map
  leafletMap: L.map('map', {worldCopyJump: true})

  crossSection: {}

  parameters:
    mag: util.getURLParameter("mag")
    startdate: util.getURLParameter("startdate")
    enddate: util.getURLParameter("enddate")

    defaultInit: ->
      d = new Date()
      @mag = 5 unless @mag?
      @startdate = "1900/1/1" unless @startdate?
      @enddate = (d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate()) unless @enddate?


  values:
    timediff: 0    # the total time between the first event and the last
    size: 0        # number of earthquakes
    maxdepth: 0    # maximum depth of an earthquake
    mindepth: 2000 # minimum depth of an earthquake

  layers:
    baseLayer3: L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {})
    baseLayer2: L.tileLayer('http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png', {subdomains: ['otile1','otile2','otile3','otile4']})
    baseLayer1: L.tileLayer('http://{s}.tiles.mapbox.com/v3/bclc-apec.map-rslgvy56/{z}/{x}/{y}.png', {})

  drawnItems: new L.FeatureGroup() # features drawn on the map (constitute the cross-section)

  earthquakes:
    circles: []  # Array of earthquake markers
    time: []     # time of occurrence of corresponding earthquakes
    depth: []    # Array of depths of corresponding earthquakes

  array: []

  editing: false # state of the map

  plateBoundaries: new L.KML("plates.kml", { async: true })

  # toggle plate boundaries
  plateToggle: ->
    if $("#plates").is(':checked')
      @leafletMap.addLayer(@plateBoundaries) # checked
    else
      @leafletMap.removeLayer(@plateBoundaries) # unchecked

  #  add earthquake event
  mapAdder: (i) ->
    if !@leafletMap.hasLayer(@earthquakes.circles[i])
      @earthquakes.circles[i].addTo(@leafletMap)

    @earthquakes.circles[i].setStyle({
      fillOpacity: 0.5,
      fillColor: "#" + rainbow.colourAt(@earthquakes.depth[i])
    })
    i++
    while @leafletMap.hasLayer(@earthquakes.circles[i])
      @leafletMap.removeLayer(@earthquakes.circles[i])
      i++

    $("#time").html(util.timeConverter(@earthquakes.time[i]))
    @controller.snd.play()

  # remove earthquake event
  mapRemover: (i) ->
    if @leafletMap.hasLayer(@earthquakes.circles[i])
      @leafletMap.removeLayer(@earthquakes.circles[i])

  # render the cross section
  render: ->
    if @editing
      @editsave()
    # TODO Do we care?
    # if @crossSection.linelength is 0
    #   alert("Draw a cross-section first")
    #   return
    # if @crossSection.linelength >= 1400
    #   alert("cross section too long")
    #   return

    pts = @crossSection.points

    @render3DFrame("../3D/index.html?x1=" + pts[0].lng +
      "&y1=" + pts[0].lat +
      "&x2=" + pts[1].lng +
      "&y2=" + pts[1].lat +
      "&x3=" + pts[2].lng +
      "&y3=" + pts[2].lat +
      "&x4=" + pts[3].lng +
      "&y4=" + pts[3].lat +
      "&mag=" + @parameters.mag +
      "&startdate=" + @parameters.startdate +
      "&enddate=" + @parameters.enddate
    ) if pts.length is 4

  render3DFrame: (url) ->
    frame = document.createElement("div")
    frame.className = 'crosssection-popup'
    frame.innerHTML = "<div class='close-button'><span class='ui-btn-icon-notext ui-icon-delete'></span></div><div class='iframe-wrapper'><iframe class='crosssection-iframe' src='" + url + "'></iframe></div>"
    document.body.appendChild(frame)

    $('.close-button').click ->
      document.body.removeChild(frame)

  # Start a new cross section drawing
  startdrawing: ->
    if @editing
      alert("Save edit before drawing a new cross-section")
      return
    @crossSection = new CrossSection(@leafletMap)

  # Edit the cross section drawing
  editdrawing: ->
    @editing = true
    @crossSection.editAddHooks()

  # save the edit
  editsave: ->
    @editing = false
    @crossSection.editRemoveHooks()

  # go back to playback
  backtonormalview: ->
    @editing = false
    @crossSection.editRemoveHooks()
    @crossSection.removeCrossSection()

module.exports = Map
