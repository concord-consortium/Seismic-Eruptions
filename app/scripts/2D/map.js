var map2D = (function () {

    //The map object with all the variables of current map being shown
    var map = {

        leafletMap: L.map('map', {worldCopyJump: true}),

        crossSection: {},

        parameters: {
            mag: getURLParameter("mag"),
            startdate: getURLParameter("startdate"),
            enddate: getURLParameter("enddate"),

            defaultInit: function () {
                var d = new Date();
                if (this.mag === undefined) {
                    this.mag = 5;
                }
                if (this.startdate === undefined) {
                    this.startdate = "2009/1/1";
                }
                if (this.enddate === undefined) {
                    this.enddate = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate();
                }
            }
        },

        values: {
            timediff: 0, //the total time between the first event and the last
            size: 0, //number of earthquakes
            maxdepth: 0, //maximum depth of an earthquake
            mindepth: 2000 //minimum depth of an earthquake
        },

        layers: {
            baseLayer3: L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {}),
            baseLayer2: L.tileLayer('http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png', {subdomains: ['otile1','otile2','otile3','otile4']}),
            baseLayer1: L.tileLayer('http://{s}.tiles.mapbox.com/v3/bclc-apec.map-rslgvy56/{z}/{x}/{y}.png', {})
        },

        drawnItems: new L.FeatureGroup(), //features drawn on the map (constitute the cross-section)

        earthquakes: {
            circles: [], // Array of earthquake markers
            time: [], // time of occurrence of corresponding earthquakes
            depth: [] // Array of depths of corresponding earthquakes
        },

        array: [],
        magarray: {},

        editing: false, //state of the map

        plateBoundaries: new L.KML("plates.kml", { // KML containing plate boundary

            async: true
        }),

        // toggle plate boundaries
        plateToggle: function () {
            if ($("#plates").is(':checked')) {
                this.leafletMap.addLayer(this.plateBoundaries); // checked
            } else {
                this.leafletMap.removeLayer(this.plateBoundaries); // unchecked
            }
        },

        //	add earthquake event
        mapAdder: function (i) {
            if (!map.leafletMap.hasLayer(map.earthquakes.circles[i])) {
                map.earthquakes.circles[i].addTo(map.leafletMap);
            }
            map.earthquakes.circles[i].setStyle({
                fillOpacity: 0.5,
                fillColor: "#" + rainbow.colourAt(map.earthquakes.depth[i])
            });
            i++;
            while (map.leafletMap.hasLayer(map.earthquakes.circles[i])) {
                map.leafletMap.removeLayer(map.earthquakes.circles[i]);
                i++;
            }
            $("#time").html(timeConverter(map.earthquakes.time[i]));
            controller.snd.play();
        },

        // remove earthquake event
        mapRemover: function (i) {
            if (map.leafletMap.hasLayer(map.earthquakes.circles[i])) {
                map.leafletMap.removeLayer(map.earthquakes.circles[i]);
            }
        },

        // render the cross section
        render: function () {
            if (this.editing) {
                alert("Save edit before viewing the cross section");
                return;
            }
            if (linelength === 0) {
                alert("Draw a cross-section first");
                return;
            } else if (linelength >= 1400) {
                alert("cross section too long");
                return;
            }
            this.render3DFrame("../3D/index.html?x1=" + toLon(y1) + "&y1=" + toLat(x1) + "&x2=" + toLon(y2) + "&y2=" + toLat(x2) + "&x3=" + toLon(y3) + "&y3=" + toLat(x3) + "&x4=" + toLon(y4) + "&y4=" + toLat(x4) + "&mag=" + map.parameters.mag + "&startdate=" + map.parameters.startdate + "&enddate=" + map.parameters.enddate);
        },

        render3DFrame: function(url) {
            var frame = document.createElement("div");
            frame.className = 'crosssection-popup';
            frame.innerHTML = "<div class='close-button'><span class='ui-btn-icon-notext ui-icon-delete'></span></div><div class='iframe-wrapper'><iframe class='crosssection-iframe' src='" + url + "'></iframe></div>";
            document.body.appendChild(frame);

            $('.close-button').click(function() {
                document.body.removeChild(frame);
            });
        },

        // Start a new cross section drawing
        startdrawing: function () {
            if (this.editing) {
                alert("Save edit before drawing a new cross-section");
                return;
            }
            this.crossSection = new CrossSection(map.leafletMap);
            //this.poly.enable();
            //cs._updateTooltip();
            //cs.initialize(map.leafletMap,map.crossSection);
        },

        //Edit the cross section drawing
        editdrawing: function () {
            this.editing = true;
            this.crossSection.editAddHooks();

        },

        //save the edit
        editsave: function () {
            this.editing = false;
            this.crossSection.editRemoveHooks();
        },

        //go back to playback
        backtonormalview: function () {
            this.editing = false;
            this.crossSection.editRemoveHooks();
            this.crossSection.removeCrossSection();
        }

    };

    //	colour gradient generator
    var rainbow = new Rainbow();
    rainbow.setNumberRange(0, 700);

    var controller = {

        // timeline of events
        timeLine: new TimelineLite({
            onUpdate: updateSlider
        }),

        //speed of events
        speed: 6,

        // output of usgs query
        script: document.createElement('script'),

        // sound of the audio
        snd: new Audio("tap.wav"), // buffers automatically when created

        initController: function () {
            loadCountFile();

            var style = {
                "clickable": true,
                "color": "#000",
                "fillColor": "#00D",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.3
            };
            var hoverStyle = {
                "fillOpacity": 1.0
            };
            var unhoverStyle = {
                "fillOpacity": 0.3
            };

            var getDepth = function(feature) {
                try {
                    return feature.geometry.geometries[0].coordinates[2];
                } catch(e) {}
                try {
                    return feature.geometry.coordinates[2];
                } catch(e) {}
                console.log('Failed to find depth!', feature);
                return '???';
            };

            // var geojsonURL = '//static.local/seismic/tiles/{z}/{x}/{y}.json';
            var geojsonURL = function(tilePoint) {
                var tileSize = this.options.tileSize,
                    nwPoint = tilePoint.multiplyBy(tileSize),
                    sePoint = nwPoint.add(new L.Point(tileSize, tileSize)),
                    nw = this._map.unproject(nwPoint),
                    se = this._map.unproject(sePoint),
                    zoom = this._getZoomForUrl(),
                    num_tiles = Math.pow(2, zoom),
                    current_mag = 7 - (zoom <= 3 ? 0 : ((zoom-3)/2));

                var url = 'http://comcat.cr.usgs.gov/fdsnws/event/1/query?starttime=1900/1/1%0000:00:00&endtime=2015/3/25%0000:00:00&eventtype=earthquake&orderby=time-asc&format=geojson' +
                         '&minmagnitude=' + current_mag +
                         '&minlatitude=' + se.lat +
                         '&maxlatitude=' + nw.lat +
                         '&minlongitude=' + nw.lng +
                         '&maxlongitude=' + se.lng +
                         '&callback=' + tilePoint.requestId;
                return url;
            };
            var geojsonTileLayer = new L.TileLayer.GeoJSONP(geojsonURL, {
                    clipTiles: false,
                    wrapPoints: true
                }, {
                    pointToLayer: function (feature, latlng) {
                        return L.circleMarker(latlng, style);
                    },
                    style: style,
                    onEachFeature: function (feature, layer) {
                        var depth = getDepth(feature);
                        layer.setStyle({
                            radius: feature.properties.mag,
                            fillColor: "#" + rainbow.colourAt(depth)
                        });
                        if (feature.properties) {
                            layer.bindPopup("Place: <b>" + feature.properties.place + "</b></br>Magnitude : <b>" + feature.properties.mag + "</b></br>Time : " + timeConverter(feature.properties.time) + "</br>Depth : " + depth + " km");
                        }
                        if (!(layer instanceof L.Point)) {
                            layer.on('mouseover', function () {
                                layer.setStyle(hoverStyle);
                            });
                            layer.on('mouseout', function () {
                                layer.setStyle(unhoverStyle);
                            });
                        }
                    }
                }
            );
            geojsonTileLayer.addTo(map.leafletMap);

        }
    };


    function getURLParameter(name) {
        return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [, ""])[1].replace(/\+/g, '%20')) || null;
    }

    //time stamp conversion
    function timeConverter(UNIX_timestamp) {
        var a = new Date(UNIX_timestamp);
        var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        var year = a.getFullYear();
        var month = months[a.getMonth()];
        var date = a.getDate();
        var hour = a.getHours();
        var min = a.getMinutes();
        var sec = a.getSeconds();
        var time = year + ' ' + month + ' ' + date;
        return time;
    }

    //load count file
    function loadCountFile() {
        $.get('count.txt', function (data) {
            array = data.split(',');
            console.log(array);
            var length = array.length;
            console.log(length);
            magarray = [];
            for (var i = 99; i >= 0; i--) {
                magarray[i] = [];
                for (var j = 0; j < length / 102; j++) {
                    if (magarray[i][j] !== undefined) magarray[i][j] = parseInt(array[(j * 102) + 2 + i]) + parseInt(magarray[i][j]);
                    else magarray[i][j] = parseInt(array[(j * 102) + 2 + i]);
                    if (j + 1 < length / 102) magarray[i][j + 1] = parseInt(magarray[i][j]);
                    if (i < 99) magarray[i][j] = parseInt(magarray[i + 1][j]) + parseInt(magarray[i][j]);
                }
            }
        });
    }

    function updateSlider() {
        $("#slider").slider("value", (controller.timeLine.progress() * map.values.timediff));
        $("#date").html(timeConverter((controller.timeLine.progress() * map.values.timediff) + map.parameters.starttime));
    }

    $("#index").on("pageshow", function (event, ui) {

        $.mobile.loading('show');

        map.leafletMap.invalidateSize(true);

        map.parameters.defaultInit();

        map.layers.baseLayer2.addTo(map.leafletMap);

        map.leafletMap.fitBounds([
            [50, 40],
            [-20, -40]
        ]);

        controller.timeLine.timeScale(controller.speed);
        controller.timeLine.pause();
        controller.initController();



        $.mobile.loading('hide');
        setTimeout(function () {
            map.leafletMap.invalidateSize();
        }, 1);
        // controller.timeLine.resume();


    });

    //buttons
    $('#play').click(function () {
        controller.timeLine.resume();
    });
    $('#pause').click(function () {
        controller.timeLine.pause();
    });
    $('#speedup').click(function () {
        controller.speed *= 1.5;
        controller.timeLine.timeScale(controller.speed);
    });
    $('#speeddown').click(function () {
        if (controller.speed >= 0.5) {
            controller.speed /= 2;
            controller.timeLine.timeScale(controller.speed);
        }
    });
    $('#changeparams').click(function () {
        controller.timeLine.pause();
    });
    $('#editparamscancel').click(function () {
        controller.timeLine.resume();
    });
    $('#editparamsenter').click(function () {
        controller.timeLine.pause();
    });


    var select1 = document.getElementById('date-1-y');
    var select2 = document.getElementById('date-2-y');
    var year = 1960;
    while (year != 2015) {
        var option1, option2;
        option1 = document.createElement("option");
        option1.setAttribute("value", parseInt(year) - 1900);
        option1.innerHTML = year;
        select1.appendChild(option1);
        option2 = document.createElement("option");
        option2.setAttribute("value", parseInt(year) - 1900);
        option2.innerHTML = year;
        select2.appendChild(option2);
        year = parseInt(year) + 1;
    }
    /////////// Drawing Controls ///////////


    $('#index').click(function () {
        $('#playcontrols').fadeIn();
        $('#slider').fadeIn();
        $('#date').fadeIn();
        setTimeout(function () {
            $('#playcontrols').fadeOut();
        }, 5000);
        setTimeout(function () {
            $('#slider').fadeOut();
            $('#date').fadeOut();
        }, 12000);
    });
    $('#playback').hover(function () {
        $('#playcontrols').fadeIn();
        $('#slider').fadeIn();
        $('#date').fadeIn();
        setTimeout(function () {
            $('#slider').fadeOut();
            $('#date').fadeOut();
            $('#playcontrols').fadeOut();
        }, 8000);
    });
    setTimeout(function () {
        $('#slider').fadeOut();
        $('#date').fadeOut();
        $('#playcontrols').fadeOut();
    }, 10000);
    var drawingMode = false;
    $('#drawingTool').click(function () {
        if (!drawingMode) {
            controller.timeLine.pause();
            $.mobile.loading('show');
            $('#playback').fadeOut();
            $('#crosssection').fadeIn();
            for (var i = 0; i < map.values.size; i++) {
                if (!map.leafletMap.hasLayer(map.earthquakes.circles[i])) {
                    map.earthquakes.circles[i].setStyle({
                        fillOpacity: 0.5,
                        fillColor: "#" + rainbow.colourAt(map.earthquakes.depth[i])
                    });
                    map.earthquakes.circles[i].addTo(map.leafletMap);
                }
            }
            $.mobile.loading('hide');
            drawingMode = true;
        }
    });
    $('#drawingToolDone').click(function () {
        if (drawingMode) {
            $.mobile.loading('show');
            $('#playback').fadeIn();
            $('#crosssection').fadeOut();
            $.mobile.loading('hide');
            drawingMode = false;
            map.leafletMap.setZoom(2);
        }
    });
    $('#mapselector').change(function () {
        if (map.leafletMap.hasLayer(map.layers.baseLayer1)) {
            map.leafletMap.removeLayer(map.layers.baseLayer1);
        }
        if (map.leafletMap.hasLayer(map.layers.baseLayer2)) {
            map.leafletMap.removeLayer(map.layers.baseLayer2);
        }
        if (map.leafletMap.hasLayer(map.layers.baseLayer3)) {
            map.leafletMap.removeLayer(map.layers.baseLayer3);
        }
        switch ($('#mapselector').val()) {
            case '1':
                map.layers.baseLayer1.addTo(map.leafletMap);
                if (map.leafletMap.hasLayer(map.layers.baseLayer2)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer2);
                }
                if (map.leafletMap.hasLayer(map.layers.baseLayer3)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer3);
                }
                break;
            case '2':
                map.layers.baseLayer2.addTo(map.leafletMap);
                if (map.leafletMap.hasLayer(map.layers.baseLayer3)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer3);
                }
                if (map.leafletMap.hasLayer(map.layers.baseLayer1)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer1);
                }
                break;
            case '3':
                map.layers.baseLayer3.addTo(map.leafletMap);
                if (map.leafletMap.hasLayer(map.layers.baseLayer2)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer2);
                }
                if (map.leafletMap.hasLayer(map.layers.baseLayer1)) {
                    map.leafletMap.removeLayer(map.layers.baseLayer1);
                }
        }
    });
    $('#date-1-y').change(function () {
        loadCount(1);
    });
    $('#date-1-m').change(function () {
        loadCount(1);
    });
    $('#date-2-y').change(function () {
        loadCount(1);
    });
    $('#date-2-m').change(function () {
        loadCount(1);
    });


    function startDrawingTool() {
        $('#overlay').fadeIn();
        $('#startDrawingToolButton').fadeOut();
        $('#Drawingtools').fadeIn();
        $("#slider").slider({
            disabled: true
        });
        document.getElementById("play").disabled = true;
        document.getElementById("pause").disabled = true;
        document.getElementById("speedup").disabled = true;
        document.getElementById("speeddown").disabled = true;
        tl.pause();
        //var current = tl.progress();
        //tl.progress(0);
        for (var i = 0; i < size; i++) {
            if (!map.leafletMap.hasLayer(circles[i])) {
                circles[i].setStyle({
                    fillOpacity: 0.5,
                    fillColor: "#" + rainbow.colourAt(depth[i])
                });
                circles[i].addTo(map.leafletMap);
            }
        }
        $('#overlay').fadeOut();
    }

    function removeDrawingTool() {
        $('#overlay').fadeIn();
        $('#startDrawingToolButton').fadeIn();
        $('#Drawingtools').fadeOut();
        //tl.resume();
        $("#slider").slider({
            disabled: false
        });
        document.getElementById("play").disabled = false;
        document.getElementById("pause").disabled = false;
        document.getElementById("speedup").disabled = false;
        document.getElementById("speeddown").disabled = false;
        $('#overlay').fadeOut();
    }


    return map;
})();
