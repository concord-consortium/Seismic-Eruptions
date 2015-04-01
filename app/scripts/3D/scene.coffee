class Scene
  initialize: ->
    @limits = require '3D/map-limits'
    if Detector.webgl
      @renderer = new THREE.WebGLRenderer({antialias:true})
      $("#rendererInfo").html("<font color='white'>WebGL Renderer</font>")
    else
      @renderer = new THREE.CanvasRenderer()
      $("#rendererInfo").html("<font color='white'>Canvas Renderer</font>")

    @renderer.setClearColor(0x777777, 1)
    canvasWidth = window.innerWidth
    canvasHeight = window.innerHeight
    @renderer.setSize(canvasWidth, canvasHeight)
    document.getElementById("WebGLCanvas").appendChild(@renderer.domElement)
    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera(25, canvasWidth / canvasHeight, 1, 100)

    @camera.lookAt(new THREE.Vector3(@limits.coords.midx-@limits.coords.leftTileLimit-2,-@limits.coords.midy+@limits.coords.topTileLimit+2,1))
    @camera.position.set(0.1953529215215685,-5.647229198648456,1.4347925563786978)
    @camera.rotation.set(1.439025394333189,0.03591325303244356,0.004758846432708524)

    @camera.up.set( 0, 0, 1 )

    @scene.add(@camera)

    # stats
    @stats = new Stats()
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.top = '0px'
    document.getElementById("WebGLCanvas").appendChild( @stats.domElement )

    controls = new THREE.OrbitControls( @camera, @renderer.domElement )
    controls.target.x = @limits.coords.midx-@limits.coords.leftTileLimit-2
    controls.target.y = -@limits.coords.midy+@limits.coords.topTileLimit+2
    controls.target.z = 1
    controls.maxDistance = 8

    starfieldgeometry  = new THREE.SphereGeometry(90, 32, 32)
    starmaterial  = new THREE.MeshBasicMaterial()
    starmaterial.map   = THREE.ImageUtils.loadTexture('../images/galaxy_starfield.png')
    starmaterial.side  = THREE.BackSide
    starmesh  = new THREE.Mesh(starfieldgeometry, starmaterial)
    @scene.add(starmesh)

    @group = new THREE.Object3D()
    if Detector.webgl
      planeGeometry = new THREE.PlaneGeometry( 1, 1, 1)
    else
      planeGeometry = new THREE.PlaneGeometry(1, 1, 1, 2,0,2)

    if Detector.webgl
      tileSource = "../images/tiles/6/"
    else
      tileSource = "http://otile1.mqcdn.com/tiles/1.0.0/sat/6/"

    for j in [0...4]
      for i in [0...4]
        glassTexture = new THREE.ImageUtils.loadTexture(tileSource+(@limits.coords.leftTileLimit+i)+"/"+(@limits.coords.topTileLimit+j)+".png")
        glassTexture.wrapS = glassTexture.wrapT = THREE.RepeatWrapping
        glassTexture.repeat.set( 1, 1 )
        planeMaterial = new THREE.MeshBasicMaterial({
          map:glassTexture
          depthWrite: false
          depthTest: false
          transparent: true
          opacity: 0.5
          side:THREE.DoubleSide
          combine: THREE.MixOperation
        })
        cubeMesh = new THREE.Mesh(planeGeometry, planeMaterial)
        cubeMesh.position.set(i+0.5-2,-j-0.5+2,1.0)
        @group.add(cubeMesh)

    @scene.add(@group)
    ambientLight = new THREE.AmbientLight(0x101010, 10.0)
    @scene.add(ambientLight)
    directionalLight = new THREE.DirectionalLight(0xffffff, 1.0)
    directionalLight.position = @camera.position
    @scene.add(directionalLight)

  animateScene: ->
    requestAnimationFrame(@animateScene.bind(this))
    @renderScene()
    @stats.update()

  renderScene: ->
    @renderer.render(@scene, @camera)

  mapToggle: ->
    if $("#maptoggle").is(':checked')
      group.traverse( ( object ) -> object.visible = true )
      group.visible = true
    else
      group.traverse( ( object ) -> object.visible = false )
      group.visible = false

  thumbnailToggle: ->
    if $("#thumbnail").is(':checked')
      $('#iframe2d').fadeIn()
    else
      $('#iframe2d').fadeOut()

module.exports = Scene
