Map = require '2D/map'
MapController = require '2D/map-controller'

class App
  constructor: ->
    @map = new Map()
    @controller = new MapController(@map)

    $("#index").on "pageshow", (event, ui) =>
      $.mobile.loading('show')
      @map.leafletMap.invalidateSize(true)
      @map.layers.baseLayer2.addTo(@map.leafletMap)

      @map.leafletMap.fitBounds L.latLngBounds(@map.parameters.nw, @map.parameters.se)

      @controller.timeLine.timeScale(@controller.speed)
      @controller.timeLine.pause()

      $.mobile.loading('hide')
      setTimeout =>
        @map.leafletMap.invalidateSize()
      , 1

      @controller.timeLine.resume() if @map.parameters.timeline

  init: ->
    # buttons
    $('#play').click ->
      @controller.timeLine.resume()

    $('#pause').click ->
      @controller.timeLine.pause()

    $('#speedup').click ->
      @controller.speed *= 1.5
      @controller.timeLine.timeScale(@controller.speed)

    $('#speeddown').click ->
      if @controller.speed >= 0.5
        @controller.speed /= 2
        @controller.timeLine.timeScale(@controller.speed)

    $('#changeparams').click ->
      @controller.timeLine.pause()

    $('#editparamscancel').click ->
      @controller.timeLine.resume()

    $('#editparamsenter').click ->
      @controller.timeLine.pause()

    ########### Quake Count info controls #########
    $('#daterange').dateRangeSlider
      arrows: false
      bounds:
        min: new Date(1900, 0, 1)
        max: Date.now()
      defaultValues:
        min: new Date(1900, 0, 1)
        max: Date.now()
      scales: [
        {
          next: (value) ->
            n = new Date(value)
            return new Date(n.setYear(value.getFullYear()+20))
          label: (value) ->
            return value.getFullYear()
        }
      ]

    $.datepicker.setDefaults
      minDate: new Date(1900,0,1)
      maxDate: 0
      changeMonth: true
      changeYear: true

    minSelected = (dateText) ->
      prevVals = $('#daterange').dateRangeSlider('values')
      newDate = new Date(dateText)
      $('#daterange').dateRangeSlider('values', newDate, prevVals.max)

    maxSelected = (dateText) ->
      prevVals = $('#daterange').dateRangeSlider('values')
      newDate = new Date(dateText)
      $('#daterange').dateRangeSlider('values', prevVals.min, newDate)

    $('.ui-rangeSlider-leftLabel').click (evt) ->
      $('.ui-rangeSlider-leftLabel').datepicker('dialog', $('#daterange').dateRangeSlider('values').min, minSelected, {}, evt)

    $('.ui-rangeSlider-rightLabel').click (evt) ->
      $('.ui-rangeSlider-rightLabel').datepicker('dialog', $('#daterange').dateRangeSlider('values').max, maxSelected, {}, evt)

    formatDate = (date) ->
      return date.getFullYear() + '/' + (date.getMonth()+1) + '/' + date.getDate()

    elem = null
    $('#getQuakeCount').click =>
      $(this).addClass('ui-disabled')
      $('#quake-count').html("Earthquakes: ???")

      range = $('#daterange').dateRangeSlider('values')
      starttime = formatDate(range.min)
      endtime = formatDate(range.max)

      elem = document.createElement('script')
      elem.src = 'http://comcat.cr.usgs.gov/fdsnws/event/1/count?starttime=' + starttime + '&endtime=' + endtime + '&eventtype=earthquake&format=geojson' + @geojsonParams()
      elem.id = 'quake-count-script'
      document.body.appendChild(elem)

    window.updateQuakeCount = (result) ->
      $('#quake-count').html("Earthquakes: " + result.count)
      velem = document.getElementById('quake-count-script')
      document.body.removeChild(elem)
      $('#getQuakeCount').removeClass('ui-disabled')

    ########### Drawing Controls ###########

    $('#index').click ->
      $('#playcontrols').fadeIn()
      $('#slider').fadeIn()
      $('#date').fadeIn()
      setTimeout ->
        $('#playcontrols').fadeOut()
      , 5000
      setTimeout ->
        $('#slider').fadeOut()
        $('#date').fadeOut()
      , 12000

    $('#playback').hover ->
      $('#playcontrols').fadeIn()
      $('#slider').fadeIn()
      $('#date').fadeIn()
      setTimeout ->
        $('#slider').fadeOut()
        $('#date').fadeOut()
        $('#playcontrols').fadeOut()
      , 8000

    setTimeout ->
      $('#slider').fadeOut()
      $('#date').fadeOut()
      $('#playcontrols').fadeOut()
    , 10000

    drawingMode = false
    $('#drawingTool').click =>
      if !drawingMode
        @controller.timeLine.pause()
        $.mobile.loading('show')
        $('#playback').fadeOut()
        $('#crosssection').fadeIn()
        for i in [0...(@map.values.size)]
          if !@map.leafletMap.hasLayer(@map.earthquakes.circles[i])
            @map.earthquakes.circles[i].setStyle
              fillOpacity: 0.5
              fillColor: "#" + @rainbow.colourAt(@map.earthquakes.depth[i])

            @map.earthquakes.circles[i].addTo(@map.leafletMap)

        $.mobile.loading('hide')
        drawingMode = true

    $('#drawingToolDone').click =>
      if drawingMode
        $.mobile.loading('show')
        $('#playback').fadeIn()
        $('#crosssection').fadeOut()
        $.mobile.loading('hide')
        drawingMode = false
        @map.leafletMap.setZoom(2)

    $('#mapselector').change =>
      if @map.leafletMap.hasLayer(@map.layers.baseLayer1)
        @map.leafletMap.removeLayer(@map.layers.baseLayer1)
      if @map.leafletMap.hasLayer(@map.layers.baseLayer2)
        @map.leafletMap.removeLayer(@map.layers.baseLayer2)
      if @map.leafletMap.hasLayer(@map.layers.baseLayer3)
        @map.leafletMap.removeLayer(@map.layers.baseLayer3)
      switch $('#mapselector').val()
        when '1'
          @map.layers.baseLayer1.addTo(@map.leafletMap)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer2)
            @map.leafletMap.removeLayer(@map.layers.baseLayer2)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer3)
            @map.leafletMap.removeLayer(@map.layers.baseLayer3)
        when '2'
          @map.layers.baseLayer2.addTo(@map.leafletMap)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer3)
            @map.leafletMap.removeLayer(@map.layers.baseLayer3)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer1)
            @map.leafletMap.removeLayer(@map.layers.baseLayer1)
        when '3'
          @map.layers.baseLayer3.addTo(@map.leafletMap)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer2)
            @map.leafletMap.removeLayer(@map.layers.baseLayer2)
          if @map.leafletMap.hasLayer(@map.layers.baseLayer1)
            @map.leafletMap.removeLayer(@map.layers.baseLayer1)

    $('#date-1-y').change ->
      loadCount(1)

    $('#date-1-m').change ->
      loadCount(1)

    $('#date-2-y').change ->
      loadCount(1)

    $('#date-2-m').change ->
      loadCount(1)

    startDrawingTool = ->
      $('#overlay').fadeIn()
      $('#startDrawingToolButton').fadeOut()
      $('#Drawingtools').fadeIn()
      $("#slider").slider
        disabled: true

      document.getElementById("play").disabled = true
      document.getElementById("pause").disabled = true
      document.getElementById("speedup").disabled = true
      document.getElementById("speeddown").disabled = true
      tl.pause()

      for i in [0...size] by 1
        if !@map.leafletMap.hasLayer(@map.earthquakes.circles[i])
          @map.earthquakes.circles[i].setStyle
            fillOpacity: 0.5,
            fillColor: "#" + @rainbow.colourAt(@map.earthquakes.depth[i])

          @map.earthquakes.circles[i].addTo(@map.leafletMap)

      $('#overlay').fadeOut()

    removeDrawingTool = ->
      $('#overlay').fadeIn()
      $('#startDrawingToolButton').fadeIn()
      $('#Drawingtools').fadeOut()

      $("#slider").slider
        disabled: false

      document.getElementById("play").disabled = false
      document.getElementById("pause").disabled = false
      document.getElementById("speedup").disabled = false
      document.getElementById("speeddown").disabled = false

      $('#overlay').fadeOut()

  geojsonParams: ->
    bounds = @map.leafletMap.getBounds()
    nw = bounds.getNorthWest()
    se = bounds.getSouthEast()
    mag = $('#magnitude-slider').val()
    latSpan = nw.lat - se.lat
    lngSpan = se.lng - nw.lng

    if latSpan >= 180 or latSpan <= -180
      nw.lat = 90
      se.lat = -90

    if lngSpan >= 180 or lngSpan <= -180
      nw.lng = -180
      se.lng = 180

    url = '&minmagnitude=' + mag +
          '&minlatitude=' + se.lat +
          '&maxlatitude=' + nw.lat +
          '&minlongitude=' + nw.lng +
          '&maxlongitude=' + se.lng +
          '&callback=updateQuakeCount'
    return url

module.exports = App
