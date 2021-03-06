Map = require '2D/map'
MapController = require '2D/map-controller'

class App
  constructor: ->
    @util = require 'common/util'
    @map = new Map()
    @controller = new MapController(@map)

    $("#index").on "pageshow", (event, ui) =>
      $.mobile.loading('show')
      @map.leafletMap.invalidateSize(true)
      @map.layers.baseLayer2.addTo(@map.leafletMap)

      if @map.parameters.center? and @map.parameters.zoom?
        @map.leafletMap.setView @map.parameters.center, @map.parameters.zoom
      else
        @map.leafletMap.fitBounds L.latLngBounds(@map.parameters.nw, @map.parameters.se)

      @controller.initController()

      @controller.timeLine.timeScale(@controller.speed)
      @controller.timeLine.pause()

      $.mobile.loading('hide')
      setTimeout =>
        @map.leafletMap.invalidateSize()
      , 1

      @init()

  init: ->
    # buttons
    $('#play').click =>
      @controller.timeLine.resume()

    $('#pause').click =>
      @controller.timeLine.pause()

    $('#speedup').click =>
      @controller.speed *= 1.5
      @controller.timeLine.timeScale(@controller.speed)

    $('#speeddown').click =>
      if @controller.speed >= 0.5
        @controller.speed /= 2
        @controller.timeLine.timeScale(@controller.speed)

    $('#changeparams').click =>
      @controller.timeLine.pause()

    $('#editparamscancel').click =>
      @controller.timeLine.resume()

    $('#editparamsenter').click =>
      @controller.timeLine.pause()

    if @map.parameters.timeline
      $('#options-button').attr 'href', '#options-details'

    ########### Quake Count info controls #########
    $('#daterange').dateRangeSlider
      arrows: false
      bounds:
        min: new Date(1900, 0, 1)
        max: Date.now()
      defaultValues:
        min: new Date(@map.parameters.startdate)
        max: new Date(@map.parameters.enddate)
      scales: [
        {
          next: (value) ->
            n = new Date(value)
            return new Date(n.setYear(value.getFullYear() + 20))
          label: (value) ->
            return value.getFullYear()
        }
      ]

    $('#magnitude-slider').val(@map.parameters.desiredMag || @map.parameters.mag).slider('refresh')

    $.datepicker.setDefaults
      minDate: new Date(1900, 0, 1)
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
      $('.ui-rangeSlider-leftLabel').datepicker('dialog',
        $('#daterange').dateRangeSlider('values').min, minSelected, {}, evt)

    $('.ui-rangeSlider-rightLabel').click (evt) ->
      $('.ui-rangeSlider-rightLabel').datepicker('dialog',
              $('#daterange').dateRangeSlider('values').max, maxSelected, {}, evt)

    updateShareLink = =>
      range = $('#daterange').dateRangeSlider('values')
      query = @util.queryString @map,
        startdate: @util.usgsDate(range.min)
        enddate: @util.usgsDate(range.max)
        mag: $('#magnitude-slider').val()
      url = window.location.origin + window.location.pathname + query
      $('#share-link').attr "href", url
      $('#share-link').text url

    elem = null
    $('#getQuakeCount').click =>
      $(this).addClass('ui-disabled')
      $('#quake-count').html("Earthquakes: ???")

      range = $('#daterange').dateRangeSlider('values')
      starttime = @util.usgsDate(range.min)
      endtime = @util.usgsDate(range.max)

      elem = document.createElement('script')
      elem.src = "http://earthquake.usgs.gov/fdsnws/event/1/count?starttime=#{starttime}\
        &endtime=#{endtime}&eventtype=earthquake&format=geojson#{@geojsonParams()}"
      elem.id = 'quake-count-script'
      document.body.appendChild(elem)

      updateShareLink()

    window.updateQuakeCount = (result) ->
      $('#quake-count').html("Earthquakes: " + result.count)
      elem = document.getElementById('quake-count-script')
      document.body.removeChild(elem)
      $('#getQuakeCount').removeClass('ui-disabled')

    $('#loadSelectedData').click =>
      range = $('#daterange').dateRangeSlider('values')
      @map.parameters.startdate = @util.usgsDate(range.min)
      @map.parameters.enddate = @util.usgsDate(range.max)
      @map.parameters.desiredMag = $('#magnitude-slider').val()
      @controller.reloadData()
      history.pushState {mapParams: @map.parameters}, 'Seismic Eruptions', @util.queryString(@map)

      updateShareLink()

    # FIXME This doesn't seem to end up working...
    # $(window).on "navigate", (event, data) =>
    #   if data.state?.mapParams?
    #     console.log("One of our states came back!")
    #     @map.parameters = data.state.mapParams
    #     @controller.reloadData()

    $('#share-wrapper').hide()
    $('#shareSelectedData').click ->
      updateShareLink()
      $('#share-wrapper').show()

    ########### Drawing Controls ###########
    # if @map.parameters.timeline
      # $('#index').click ->
        # $('#playcontrols').fadeIn()
        # $('#slider-wrapper').fadeIn()
        # $('#date').fadeIn()
        # setTimeout ->
        #   $('#playcontrols').fadeOut()
        # , 5000
        # setTimeout ->
          # $('#slider-wrapper').fadeOut()
          # $('#date').fadeOut()
        # , 12000

    drawingMode = false
    $('#drawingTool').click =>
      if !drawingMode
        @controller.timeLine.pause()
        $.mobile.loading('show')
        # $('#playback').fadeOut()
        $('#crosssection').fadeIn()
        for i in [0...(@map.values.size)]
          if !@map.leafletMap.hasLayer(@map.earthquakes.circles[i])
            @map.earthquakes.circles[i].setStyle
              fillOpacity: 0.5
              fillColor: "#" + @controller.rainbow.colourAt(@map.earthquakes.depth[i])

            @map.earthquakes.circles[i].addTo(@map.leafletMap)

        $.mobile.loading('hide')
        drawingMode = true

    $('#drawingToolDone').click =>
      if drawingMode
        $.mobile.loading('show')
        # $('#playback').fadeIn() if @map.parameters.timeline
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

      for i in [0...(@map.values.size)] by 1
        if !@map.leafletMap.hasLayer(@map.earthquakes.circles[i])
          @map.earthquakes.circles[i].setStyle
            fillOpacity: 0.5,
            fillColor: "#" + @controller.rainbow.colourAt(@map.earthquakes.depth[i])

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

    url = "&minmagnitude=#{mag}\
          &minlatitude=#{se.lat}\
          &maxlatitude=#{nw.lat}\
          &minlongitude=#{nw.lng}\
          &maxlongitude=#{se.lng}\
          &callback=updateQuakeCount"
    return url

module.exports = App
