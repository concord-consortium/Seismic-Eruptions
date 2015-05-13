Scene = require '3D/scene'
Plot  = require '3D/plot'
DataLoader = require 'common/data-loader'

class Main
  constructor: ->
    @util = require('common/util')
    @limits = require('3D/map-limits')

  start: ->
    $.mobile.loading('show')
    @scene = new Scene()
    @scene.initialize()
    $.mobile.loading('hide')
    @scene.animateScene()

    @plot = new Plot()
    @plot.setup(@scene)
    @plot.loadquakes()

  miniMap: ->
    rainbow = new Rainbow()
    script = document.createElement('script')
    map = L.map('map')

    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
      maxZoom: 6
    }).addTo(map);

    # adding earthquake points

    ptToLayer = (feature, latlng) ->
      return L.circleMarker(latlng, {
        radius: 3
        fillColor: "#"+rainbow.colourAt(feature.properties.mag)
        color: "#000"
        weight: 1
        opacity: 1
        fillOpacity: 1
      })

    loader = new DataLoader()
    url = 'http://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&orderby=time-asc' +
      '&starttime=' + @util.getURLParameter("startdate") + 'T00:00:00' +
      '&endtime=' + @util.getURLParameter("enddate") + 'T23:59:59' +
      '&minmagnitude=' + @util.getURLParameter("mag") +
      '&minlatitude='  + Math.min(@limits.latlng.y1, @limits.latlng.y2, @limits.latlng.y3, @limits.latlng.y4) +
      '&maxlatitude='  + Math.max(@limits.latlng.y1, @limits.latlng.y2, @limits.latlng.y3, @limits.latlng.y4) +
      '&minlongitude=' + Math.min(@limits.latlng.x1, @limits.latlng.x2, @limits.latlng.x3, @limits.latlng.x4) +
      '&maxlongitude=' + Math.max(@limits.latlng.x1, @limits.latlng.x2, @limits.latlng.x3, @limits.latlng.x4)

    loader.load(url).then (results) =>
      size = results.features.length
      for feature in results.features
        L.geoJson(feature, {
          pointToLayer: ptToLayer
        }).bindPopup("Place: <b>"+feature.properties.place+"</b></br>Magnitude : <b>"+ feature.properties.mag+"</b></br>Time : "+@util.timeConverter(feature.properties.time)+"</br>Depth : "+feature.geometry.coordinates[2]+" km").addTo(map)

      L.polygon([
            [parseFloat(@limits.latlng.y1),parseFloat(@limits.latlng.x1)],
            [parseFloat(@limits.latlng.y2),parseFloat(@limits.latlng.x2)],
            [parseFloat(@limits.latlng.y3),parseFloat(@limits.latlng.x3)],
            [parseFloat(@limits.latlng.y4),parseFloat(@limits.latlng.x4)]
          ]).addTo(map)
      map.fitBounds([[parseFloat(@limits.latlng.y1),parseFloat(@limits.latlng.x1)],
            [parseFloat(@limits.latlng.y2),parseFloat(@limits.latlng.x2)],
            [parseFloat(@limits.latlng.y3),parseFloat(@limits.latlng.x3)],
            [parseFloat(@limits.latlng.y4),parseFloat(@limits.latlng.x4)]])
      map.setZoom(map.getZoom()-1)

module.exports = Main
