DataLoader = require 'common/data-loader'

class Plot
  setup: (@scene)->
    @util = require 'common/util'
    @limits = require '3D/map-limits'
    @rainbow = new Rainbow()
    @rainbow.setSpectrum('#A52A2A', '#FF0000', '#800080', '#FF00FF', "#2f9898", "#266fc1", "#0000ff", "#00FFFF", "#50f950", "#FFFF00")
    @rainbow.setNumberRange(0, 700)
    @sphereParent = new THREE.Object3D()

    @mag = @util.getURLParameter("mag")
    @startdate = @util.getURLParameter("startdate") || "2009/1/1"
    @enddate = @util.getURLParameter("enddate")
    unless enddate?
      d = new Date()
      curr_year = d.getFullYear()
      curr_month = d.getMonth()+1
      curr_date = d.getDate()
      @enddate = curr_year+'/'+curr_month+'/'+curr_date

  loadquakes: ->
    @count = 0
    @maxdepth = 0
    @mindepth = 999
    @maxmag = 0
    @minmag = 999

    loader = new DataLoader()
    url = 'http://comcat.cr.usgs.gov/fdsnws/event/1/query?format=geojson&orderby=time-asc' +
      '&minmagnitude='+@mag +
      '&starttime='+@startdate+'%2000:00:00' +
      '&endtime='+@enddate+'%2023:59:59' +
      '&minlatitude='  + Math.min(@limits.latlng.y1, @limits.latlng.y2, @limits.latlng.y3, @limits.latlng.y4) +
      '&maxlatitude='  + Math.max(@limits.latlng.y1, @limits.latlng.y2, @limits.latlng.y3, @limits.latlng.y4) +
      '&minlongitude=' + Math.min(@limits.latlng.x1, @limits.latlng.x2, @limits.latlng.x3, @limits.latlng.x4) +
      '&maxlongitude=' + Math.max(@limits.latlng.x1, @limits.latlng.x2, @limits.latlng.x3, @limits.latlng.x4)

    loader.load(url).then (results) =>
      size = results.features.length
      if size is 0
        alert("No earthquakes inside the cross section in given time range")
        return

      for feature in results.features
        if @_rect @util.convertCoordinatesx(feature.geometry.coordinates[0]), @util.convertCoordinatesy(feature.geometry.coordinates[1])
          @count++
          @_processFeature(feature)

      $("#info").html("</br></br>total earthquakes : "+size+"</br>minimum depth : "+@mindepth+" km</br>maximum depth : "+@maxdepth+" km</br></br></br><div class='ui-body ui-body-a'><p><a href='http://github.com/gizmoabhinav/Seismic-Eruptions'>Link to the project</a></p></div>")
      $("#startdate").html("Start date : "+@util.timeConverter(@startdate))
      $("#enddate").html("End date : "+@util.timeConverter(@enddate))
      $("#magcutoff").html("Cutoff magnitude : "+@minmag)


      @sphereParent.position.set(0,0,0)
      @scene.scene.add(@sphereParent)
      # generate the box
      vertex1 = new THREE.Vector3( @limits.coords.x1-@limits.coords.leftTileLimit-2, -@limits.coords.y1+@limits.coords.topTileLimit+2,1 )
      vertex2 = new THREE.Vector3( @limits.coords.x2-@limits.coords.leftTileLimit-2, -@limits.coords.y2+@limits.coords.topTileLimit+2,1 )
      vertex3 = new THREE.Vector3( @limits.coords.x3-@limits.coords.leftTileLimit-2, -@limits.coords.y3+@limits.coords.topTileLimit+2,1 )
      vertex4 = new THREE.Vector3( @limits.coords.x4-@limits.coords.leftTileLimit-2, -@limits.coords.y4+@limits.coords.topTileLimit+2,1 )
      vertex5 = new THREE.Vector3( @limits.coords.x1-@limits.coords.leftTileLimit-2, -@limits.coords.y1+@limits.coords.topTileLimit+2,1.0-(@maxdepth/1000) )
      vertex6 = new THREE.Vector3( @limits.coords.x2-@limits.coords.leftTileLimit-2, -@limits.coords.y2+@limits.coords.topTileLimit+2,1.0-(@maxdepth/1000) )
      vertex7 = new THREE.Vector3( @limits.coords.x3-@limits.coords.leftTileLimit-2, -@limits.coords.y3+@limits.coords.topTileLimit+2,1.0-(@maxdepth/1000) )
      vertex8 = new THREE.Vector3( @limits.coords.x4-@limits.coords.leftTileLimit-2, -@limits.coords.y4+@limits.coords.topTileLimit+2,1.0-(@maxdepth/1000) )
      box = new THREE.Geometry()
      box.vertices.push( vertex1 )
      box.vertices.push( vertex2 )
      box.vertices.push( vertex3 )
      box.vertices.push( vertex4 )
      box.vertices.push( vertex5 )
      box.vertices.push( vertex6 )
      box.vertices.push( vertex7 )
      box.vertices.push( vertex8 )
      box.faces.push( new THREE.Face3( 6,5,4 ) )
      box.faces.push( new THREE.Face3( 4,7,6 ) )
      box.faces.push( new THREE.Face3( 4,5,6 ) )
      box.faces.push( new THREE.Face3( 6,7,4 ) )
      box.faces.push( new THREE.Face3( 4,1,0 ) )
      box.faces.push( new THREE.Face3( 5,1,4 ) )
      box.faces.push( new THREE.Face3( 0,1,4 ) )
      box.faces.push( new THREE.Face3( 4,1,5 ) )
      box.faces.push( new THREE.Face3( 1,2,5 ) )
      box.faces.push( new THREE.Face3( 5,2,6 ) )
      box.faces.push( new THREE.Face3( 5,2,1 ) )
      box.faces.push( new THREE.Face3( 6,2,5 ) )
      box.faces.push( new THREE.Face3( 2,3,6 ) )
      box.faces.push( new THREE.Face3( 6,3,7 ) )
      box.faces.push( new THREE.Face3( 6,3,2 ) )
      box.faces.push( new THREE.Face3( 7,3,6 ) )
      box.faces.push( new THREE.Face3( 3,0,7 ) )
      box.faces.push( new THREE.Face3( 7,0,3 ) )
      box.faces.push( new THREE.Face3( 7,0,4 ) )
      box.faces.push( new THREE.Face3( 4,0,7 ) )
      rectmaterial = new THREE.MeshBasicMaterial({color: 0x770000,transparency : true,opacity:0.05,wireframe : false})
      mesh = new THREE.Mesh(box, rectmaterial)
      lines = new THREE.Geometry()
      lines.vertices.push( vertex1 )
      lines.vertices.push( vertex2 )
      lines.vertices.push( vertex3 )
      lines.vertices.push( vertex4 )
      lines.vertices.push( vertex1 )
      lines.vertices.push( vertex5 )
      lines.vertices.push( vertex6 )
      lines.vertices.push( vertex7 )
      lines.vertices.push( vertex8 )
      lines.vertices.push( vertex5 )
      lines.vertices.push( vertex6 )
      lines.vertices.push( vertex2 )
      lines.vertices.push( vertex3 )
      lines.vertices.push( vertex7 )
      lines.vertices.push( vertex8 )
      lines.vertices.push( vertex4 )
      # lines
      line = new THREE.Line( lines, new THREE.LineBasicMaterial( { color: 0xffffff, opacity: 1 } ) )
      @scene.scene.add( line )
      @scene.controls.target.z = 1.0-(@maxdepth/2000)

    document.getElementById("frame").src="frame.html?x1="+@limits.latlng.x1+"&x2="+@limits.latlng.x2+"&x3="+@limits.latlng.x3+"&x4="+@limits.latlng.x4+"&y1="+@limits.latlng.y1+"&y2="+@limits.latlng.y2+"&y3="+@limits.latlng.y3+"&y4="+@limits.latlng.y4+"&startdate="+@startdate+"&enddate="+@enddate+"&mag="+@mag

  _processFeature: (feature)->
    @_checkMinMax(feature)
    @_createSphere(feature)

  _checkMinMax: (feature)->
    if feature.geometry.coordinates[2] > @maxdepth
      @maxdepth = feature.geometry.coordinates[2]
    if feature.geometry.coordinates[2] < @mindepth
      @mindepth = feature.geometry.coordinates[2]
    if feature.properties.mag < @minmag
      @minmag = feature.properties.mag
    if feature.properties.mag > @maxmag
      @maxmag = feature.properties.mag

  _createSphere: (feature)->
    radius = 0.0025*Math.pow(2,(feature.properties.mag)*4/(10))
    latVal = feature.geometry.coordinates[0]
    lonVal = feature.geometry.coordinates[1]
    depth = feature.geometry.coordinates[2]
    sphereGeometry = new THREE.SphereGeometry( radius, 8, 8 )
    sphereMaterial = new THREE.MeshPhongMaterial( { color: parseInt('0x'+@rainbow.colourAt(feature.geometry.coordinates[2])) , overdraw: false } )
    sphere = new THREE.Mesh( sphereGeometry, sphereMaterial )
    sphere.position.set(@util.convertCoordinatesx(latVal)-@limits.coords.leftTileLimit-2,-@util.convertCoordinatesy(lonVal)+@limits.coords.topTileLimit+2,1.0-(depth/1000))
    @sphereParent.add( sphere )

  _rect: (x,y) ->
    bax = @limits.coords.x2 - @limits.coords.x1
    bay = @limits.coords.y2 - @limits.coords.y1
    dax = @limits.coords.x4 - @limits.coords.x1
    day = @limits.coords.y4 - @limits.coords.y1

    if ((x - @limits.coords.x1) * bax + (y - @limits.coords.y1) * bay < 0.0)
      return false
    if ((x - @limits.coords.x2) * bax + (y - @limits.coords.y2) * bay > 0.0)
      return false
    if ((x - @limits.coords.x1) * dax + (y - @limits.coords.y1) * day < 0.0)
      return false
    if ((x - @limits.coords.x4) * dax + (y - @limits.coords.y4) * day > 0.0)
      return false

    return true

module.exports = Plot
