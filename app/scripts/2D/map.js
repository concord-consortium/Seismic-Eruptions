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

            var getCurrentLimit = function(zoom, tileSize) {
                var numTiles = Math.pow(2, zoom);
                if (zoom === 0) {
                    return 15000;
                } else if (zoom <= 3) {
                    return Math.floor(20000 / Math.pow(numTiles,2));
                }
                // Figure out how many tiles are actually displaying, and limit based on that
                var bounds = map.leafletMap.getBounds(),
                    nw = bounds.getNorthWest(),
                    se = bounds.getSouthEast(),
                    nwPixel = map.leafletMap.project(nw),
                    sePixel = map.leafletMap.project(se),
                    nwTile = nwPixel.divideBy(tileSize),
                    seTile = sePixel.divideBy(tileSize),
                    left = Math.floor(nwTile.x),
                    right = Math.floor(seTile.x),
                    top = Math.floor(nwTile.y),
                    bottom = Math.floor(seTile.y),
                    width, height;

                // debugger;
                // Factor in world wrapping
                if (left > right) {
                    left = left - numTiles;
                }
                if (top > bottom) {
                    top = top - numTiles;
                }

                width = right - left;
                height = bottom - top;

                return Math.floor(15000/(width*height));
            };

            var getCurrentMag = function(zoom) {
                     if (zoom > 8) { return 2; }
                else if (zoom > 6) { return 3; }
                else if (zoom > 3) { return 4; }
                else               { return 5; }
            };

            var geojsonURL = function(tileInfo) {
                var tileSize = tileInfo.tileSize,
                    tilePoint = L.point(tileInfo.x, tileInfo.y),
                    nwPoint = tilePoint.multiplyBy(tileSize),
                    sePoint = nwPoint.add(new L.Point(tileSize, tileSize)),
                    nw = map.leafletMap.unproject(nwPoint),
                    se = map.leafletMap.unproject(sePoint),
                    zoom = tileInfo.z;

                var url = '&limit=' + getCurrentLimit(zoom, tileSize) +
                         '&minmagnitude=' + getCurrentMag(zoom) +
                         '&minlatitude=' + se.lat +
                         '&maxlatitude=' + nw.lat +
                         '&minlongitude=' + nw.lng +
                         '&maxlongitude=' + se.lng +
                         '&callback=' + tileInfo.requestId;
                return url;
            };

            var geojsonTileLayer = new L.TileLayer.GeoJSONP('http://comcat.cr.usgs.gov/fdsnws/event/1/query?starttime=1900/1/1%0000:00:00&eventtype=earthquake&orderby=time&format=geojson{url_params}', {
                    url_params: geojsonURL,
                    clipTiles: false,
                    wrapPoints: false
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

            var spinnerOpts = {
                lines: 13,
                length: 10,
                width: 7,
                radius: 10,
                top: '37px',
                left: '70px',
                color: '#cccccc',
                shadow: true
            };
            geojsonTileLayer.on('loading', function (event) {
                map.leafletMap.spin(true, spinnerOpts);
            });

            geojsonTileLayer.on('load', function (event) {
                map.leafletMap.spin(false);
            });

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

    /////////// Quake Count info controls /////////
    $('#daterange').dateRangeSlider({
        arrows: false,
        bounds: {
            min: new Date(1900, 0, 1),
            max: Date.now()
        },
        defaultValues: {
            min: new Date(1900, 0, 1),
            max: Date.now()
        },
        scales: [{
            next: function(value) {
                var next = new Date(value);
                return new Date(next.setYear(value.getFullYear()+20));
            },
            label: function(value) {
                return value.getFullYear();
            }
        }]
    });

    $.datepicker.setDefaults({
        minDate: new Date(1900,0,1),
        maxDate: 0,
        changeMonth: true,
        changeYear: true
    });
    var minSelected = function(dateText) {
        var prevVals = $('#daterange').dateRangeSlider('values'),
            newDate = new Date(dateText);
        $('#daterange').dateRangeSlider('values', newDate, prevVals.max);
    };
    var maxSelected = function(dateText) {
        var prevVals = $('#daterange').dateRangeSlider('values'),
            newDate = new Date(dateText);
        $('#daterange').dateRangeSlider('values', prevVals.min, newDate);
    };
    $('.ui-rangeSlider-leftLabel').click(function(evt) {
        $('.ui-rangeSlider-leftLabel').datepicker('dialog', $('#daterange').dateRangeSlider('values').min, minSelected, {}, evt);
    });
    $('.ui-rangeSlider-rightLabel').click(function(evt) {
        $('.ui-rangeSlider-rightLabel').datepicker('dialog', $('#daterange').dateRangeSlider('values').max, maxSelected, {}, evt);
    });
    var formatDate = function(date) {
        return date.getFullYear() + '/' + (date.getMonth()+1) + '/' + date.getDate();
    };


    var geojsonParams = function() {
        var bounds = map.leafletMap.getBounds(),
                    nw = bounds.getNorthWest(),
                    se = bounds.getSouthEast(),
                    mag = $('#magnitude-slider').val(),
                    latSpan = nw.lat - se.lat,
                    lngSpan = se.lng - nw.lng;

        if (latSpan >= 180 || latSpan <= -180) {
            nw.lat = 90;
            se.lat = -90;
        }

        if (lngSpan >= 180 || lngSpan <= -180) {
            nw.lng = -180;
            se.lng = 180;
        }

        var url = '&minmagnitude=' + mag +
                 '&minlatitude=' + se.lat +
                 '&maxlatitude=' + nw.lat +
                 '&minlongitude=' + nw.lng +
                 '&maxlongitude=' + se.lng +
                 '&callback=updateQuakeCount';
        return url;
    };
    $('#getQuakeCount').click(function() {
        $(this).addClass('ui-disabled');
        $('#quake-count').html("Earthquakes: ???");
        var range = $('#daterange').dateRangeSlider('values'),
          starttime = formatDate(range.min),
          endtime = formatDate(range.max);
        var elem = document.createElement('script');
        elem.src = 'http://comcat.cr.usgs.gov/fdsnws/event/1/count?starttime=' + starttime + '&endtime=' + endtime + '&eventtype=earthquake&format=geojson' + geojsonParams();
        elem.id = 'quake-count-script';
        document.body.appendChild(elem);
    });
    window.updateQuakeCount = function(result) {
        $('#quake-count').html("Earthquakes: " + result.count);
        var elem = document.getElementById('quake-count-script');
        document.body.removeChild(elem);
        $('#getQuakeCount').removeClass('ui-disabled');
    };
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
