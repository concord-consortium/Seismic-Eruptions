var polygonArr = new Array();
var lng0,lng1,lat0,lat1;
var touchstart = true;
var touchend = false;
var width=0.25;
var linelength = 0;
var length,ratio1,ratio2,x1,y1,x2,y2,x3,y3,x4,y4;

var lat,lng,mlat,mlng,mlatlng,initDistance,initWidth,resizemarkervar,movemarkervar,endmarker1,endmarker2;
var CrossSection = L.Class.extend({

	options: {
		allowIntersection: true,
		repeatMode: false,
		drawError: {
			color: '#b00b00',
			timeout: 2500
		},
		icon: new L.DivIcon({
			iconSize: new L.Point(8, 8),
			className: 'leaflet-div-icon leaflet-editing-icon'
		}),
		guidelineDistance: 10,
		maxGuideLineLength: 4000,
		shapeOptions: {
			stroke: true,
			color: '#ff0000',
			weight: 4,
			opacity: 0.5,
			fill: false,
			clickable: true
		},
		metric: true, // Whether to use the metric meaurement system or imperial
		showLength: true, // Whether to display distance in the tooltip
		zIndexOffset: 2000 // This should be > than the highest z-index any map layers
	},
	
	enable: function () {
		if (this._enabled) { return; }
		
		this._enabled = true;
	},

	disable: function () {
		if (!this._enabled) { return; }
		
		this_enabled = false;
	},
	
	initialize: function (map) {
		this._crossSection = {line:{},rectangle:{}};
		this._map = map;
		this._container = map._container;
		this._overlayPane = map._panes.overlayPane;
		this._popupPane = map._panes.popupPane;
		this._featureGroup = new L.FeatureGroup();
		this._drawGuide(new L.Point(0,0),new L.Point(0,0));
		this.addHooks();
	},

	addHooks: function () {
		//L.Draw.Feature.prototype.addHooks.call(this);
		
		if (this._map) {
			this._map.getContainer().focus();
			L.DomUtil.disableTextSelection();
			this._tooltip = new L.Tooltip(this._map);
			this._map.getContainer().focus();
			this._markers = [];
			this._map.dragging.disable();
			this._markerGroup = new L.LayerGroup();
			this._map.addLayer(this._markerGroup);

			this._crossSection.line = new L.Polyline([], this.options.shapeOptions);
			
		
			this._tooltip.updateContent(this._getTooltipText());

			// Make a transparent marker that will used to catch click events. These click
			// events will create the vertices. We need to do this so we can ensure that
			// we can create vertices over other map layers (markers, vector layers). We
			// also do not want to trigger any click handlers of objects we are clicking on
			// while drawing.
			
			L.DomEvent.on(this._map._container, 'touchstart', this._onTouchStart, this);
			L.DomEvent.on(this._map._container, 'touchend', this._onTouchEnd, this);
			L.DomEvent.on(this._map._container, 'touchmove', this._onTouchMove, this);
			L.DomEvent.on(this._map._container, 'touchmove', this._onTouchMove, this);
			console.log("here");
			if (!this._mouseMarker) {
				this._mouseMarker = L.marker(this._map.getCenter(), {
					icon: L.divIcon({
						className: 'leaflet-mouse-marker',
						iconAnchor: [20, 20],
						iconSize: [40, 40]
					}),
					opacity: 0,
					zIndexOffset: this.options.zIndexOffset
				});
			}

			this._mouseMarker
				.on('mousedown', this._onMouseDown, this)
				.on('touchstart', this._onMouseDown, this)
				.addTo(this._map);
			this._map
				.on('mousemove', this._onMouseMove, this)
				.on('mouseup', this._onMouseUp, this)
				.on('zoomlevelschange', this._onZoomEnd, this);
		}
	},

	removeHooks: function () {
		L.DomUtil.enableTextSelection();
			this._tooltip.dispose();
			this._tooltip = null;
			
		this._clearHideErrorTimeout();
		this._map.dragging.enable();
		this._cleanUpShape();

		// remove markers from map
		this._map.removeLayer(this._markerGroup);
		delete this._markerGroup;
		delete this._markers;

		//this._map.removeLayer(this._crossSection.line);
		//delete this._crossSection.line;

		this._mouseMarker
			.off('mousedown', this._onMouseDown, this)
			.off('mouseup', this._onMouseUp, this);
		this._map.removeLayer(this._mouseMarker);
		delete this._mouseMarker;
		// clean up DOM
		this._clearGuides();
		L.DomEvent.off(this._map._container, 'touchstart', this._onTouchStart, this);
		L.DomEvent.off(this._map._container, 'touchend', this._onTouchEnd, this);
		L.DomEvent.off(this._map._container, 'touchmove', this._onTouchMove, this);
		this._map
			.off('mousemove', this._onMouseMove, this)
			.off('mouseup', this._onMouseUp, this)
			.off('zoomlevelschange', this._onZoomEnd, this);
	},
	

	deleteLastVertex: function () {
		if (this._markers.length <= 1) {
			return;
		}

		var lastMarker = this._markers.pop(),
			poly = this._crossSection.line,
			latlng = this._crossSection.line.spliceLatLngs(poly.getLatLngs().length - 1, 1)[0];

		this._markerGroup.removeLayer(lastMarker);

		if (poly.getLatLngs().length < 2) {
			this._map.removeLayer(poly);
		}

		this._vertexChanged(latlng, false);
	},

	addVertex: function (latlng) {
		//alert(latlng.lat);
		var markersLength = this._markers.length;
		

		if (markersLength > 0 && !this.options.allowIntersection) {
			this._showErrorTooltip();
			return;
		}
		else if (this._errorShown) {
			this._hideErrorTooltip();
		}
		//this._markers.push(this._createMarker(latlng));

		this._crossSection.line.addLatLng(latlng);
		
		//polygonArr[polygonArr.length]=latlng;
		
		if (this._crossSection.line.getLatLngs().length == 2) {
		//alert(this._crossSection.line.getLatLngs()[1]);
			this._map.addLayer(this._crossSection.line);
			this._finishShape();
		}

		//this._vertexChanged(latlng, true);
		if((markersLength) == 2){
			polygonArr[1] = latlng;
			lat0 =convertCoordinatesy(polygonArr[0].lat);
			lat1 =convertCoordinatesy(polygonArr[1].lat);
			lng0 =convertCoordinatesx(polygonArr[0].lng);
			lng1 =convertCoordinatesx(polygonArr[1].lng);
			length = Math.sqrt(Math.pow((lat0)-(lat1),2)+Math.pow((lng0)-(lng1),2));
			ratio1 = length/(((lat0)-(lat1)));
			ratio2 = length/(((lng0)-(lng1)));
			x1=lat1+(width/ratio2);
			y1=lng1-(width/ratio1);
			x2=lat0+(width/ratio2);
			y2=lng0-(width/ratio1);
			x3=lat0-(width/ratio2);
			y3=lng0+(width/ratio1);
			x4=lat1-(width/ratio2);
			y4=lng1+(width/ratio1);
			this._crossSection.rectangle = new L.polygon([
						[toLat(x1),toLon(y1)],
						[toLat(x2),toLon(y2)],
						[toLat(x3),toLon(y3)],
						[toLat(x4),toLon(y4)]
					]);
			this._crossSection.rectangle.addTo(this._map);		
			this._map.fitBounds(this._crossSection.rectangle.getBounds());
			this._clearGuides();
			this.removeHooks();
			this._featureGroup.addLayer(this._crossSection.line);
			this._featureGroup.addLayer(this._crossSection.rectangle);
		}
		else{
			polygonArr = new Array();
			polygonArr[0] = latlng;
			
			if(this._map.hasLayer(this._crossSection.line))
				this._map.removeLayer(this._crossSection.line);
			if(this._map.hasLayer(this._crossSection.rectangle)){
				this._map.removeLayer(this._crossSection.rectangle);
			}
		}
	},

	_finishShape: function () {
		

		if ((!this.options.allowIntersection) || !this._shapeIsValid()) {
			this._showErrorTooltip();
			return;
		}

		this._fireCreatedEvent();
		this.disable();
		if (this.options.repeatMode) {
			this.enable();
		}
	},

	//Called to verify the shape is valid when the user tries to finish it
	//Return false if the shape is not valid
	_shapeIsValid: function () {
		return true;
	},

	_onZoomEnd: function () {
		this._updateGuide();
	},

	_onMouseMove: function (e) {
	
		var newPos = e.layerPoint,
			latlng = e.latlng;

		// Save latlng
		// should this be moved to _updateGuide() ?
		this._currentLatLng = latlng;

		this._updateTooltip(latlng);

		// Update the guide line
		this._updateGuide(newPos);

		// Update the mouse marker position
		this._mouseMarker.setLatLng(latlng);

		L.DomEvent.preventDefault(e.originalEvent);
	},

	_vertexChanged: function (latlng, added) {
		this._updateFinishHandler();

		this._updateRunningMeasure(latlng, added);

		this._clearGuides();

		this._updateTooltip();
	},

	_onMouseDown: function (e) {
		//alert("mousedown");
		var originalEvent = e.originalEvent;
		this._mouseDownOrigin = L.point(originalEvent.clientX, originalEvent.clientY);
		this._markers = [];
		this._markers.push(this._createMarker(e.latlng));
		this.addVertex(e.latlng);
	},

	_onMouseUp: function (e) {
		//alert("mouseup");
		if (this._mouseDownOrigin) {
			// We detect clicks within a certain tolerance, otherwise let it
			// be interpreted as a drag by the map
			var distance = L.point(e.originalEvent.clientX, e.originalEvent.clientY)
				.distanceTo(this._mouseDownOrigin);
			//if (Math.abs(distance) < 9 * (window.devicePixelRatio || 1)) {
					this._markers[1] = this._createMarker(e.latlng);
					this.addVertex(e.latlng);
				
			//}
			
		}
		this._mouseDownOrigin = null;
	},
	_onTouchStart: function (e) {
		if(touchstart){
		this._mouseDownOrigin = L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY);
		this._markers = [];
		this._markers[0] = this._createMarker(this._map.layerPointToLatLng(this._mouseDownOrigin));
		//this._markers.push(this._map.layerPointToLatLng(this._mouseDownOrigin));
		this.addVertex(this._map.layerPointToLatLng(this._mouseDownOrigin));
		//alert((this._map.layerPointToLatLng(this._mouseDownOrigin)));
		touchstart = false;
		touchend = true;
		}
	},
	_onTouchEnd: function (e) {
		if(touchend){
			if (this._mouseDownOrigin) {
			var distance = L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY)
				.distanceTo(this._mouseDownOrigin);
			var endpoint = this._map.layerPointToLatLng(L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY));
				
					this._markers[1] = this._createMarker(endpoint);
					
					this.addVertex(endpoint);
					touchend = false;
					
		}
		this._mouseDownOrigin = null;
		
		touchstart = true;
		}
	},
	_onTouchMove: function (e) {
		this._currentLatLng = this._map.layerPointToLatLng(L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY));

		this._updateTooltip(this._map.layerPointToLatLng(L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY)));
		
		// Update the guide line
		this._updateGuide(L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY));

		// Update the mouse marker position
		this._mouseMarker.setLatLng(this._map.layerPointToLatLng(L.point(e.changedTouches[0].clientX, e.changedTouches[0].clientY)));
		
		
	},
	_updateFinishHandler: function () {
		var markerCount = this._markers.length;
		// The last marker should have a click handler to close the polyline
		if (markerCount > 1) {
			this._markers[markerCount - 1].on('click', this._finishShape, this);
		}

		// Remove the old marker click handler (as only the last point should close the polyline)
		if (markerCount > 2) {
			this._markers[markerCount - 2].off('click', this._finishShape, this);
		}
	},

	_createMarker: function (latlng) {
		var marker = new L.Marker(latlng, {
			icon: this.options.icon,
			zIndexOffset: this.options.zIndexOffset * 2
		});

		this._markerGroup.addLayer(marker);

		return marker;
	},

	_updateGuide: function (newPos) {
	
		if(this._markers!=null)
			var markerCount = this._markers.length;
		else
			var markerCount = 0;

		if (markerCount > 0 && markerCount < 2) {
			newPos = newPos || this._map.latLngToLayerPoint(this._currentLatLng);

			// draw the guide line
			this._clearGuides();
			this._drawGuide(
				this._map.latLngToLayerPoint(this._markers[0].getLatLng()),
				newPos
			);
		}
	},

	_updateTooltip: function (latLng) {
		var text = this._getTooltipText();

		if (latLng) {
			this._tooltip.updatePosition(latLng);
		}

		if (!this._errorShown) {
			this._tooltip.updateContent(text);
		}
	},

	_drawGuide: function (pointA, pointB) {
		var length = Math.floor(Math.sqrt(Math.pow((pointB.x - pointA.x), 2) + Math.pow((pointB.y - pointA.y), 2))),
			guidelineDistance = this.options.guidelineDistance,
			maxGuideLineLength = this.options.maxGuideLineLength,
			// Only draw a guideline with a max length
			i = length > maxGuideLineLength ? length - maxGuideLineLength : guidelineDistance,
			fraction,
			dashPoint,
			dash;

		//create the guides container if we haven't yet
		if (!this._guidesContainer) {
			this._guidesContainer = L.DomUtil.create('div', 'leaflet-draw-guides', this._overlayPane);
		}
		
		
		
		//draw a dash every GuildeLineDistance
		for (; i < length; i += this.options.guidelineDistance) {
			//work out fraction along line we are
			fraction = i / length;

			//calculate new x,y point
			dashPoint = {
				x: Math.floor((pointA.x * (1 - fraction)) + (fraction * pointB.x)),
				y: Math.floor((pointA.y * (1 - fraction)) + (fraction * pointB.y))
			};

			//add guide dash to guide container
			dash = L.DomUtil.create('div', 'leaflet-draw-guide-dash', this._guidesContainer);
			dash.style.backgroundColor =
				!this._errorShown ? this.options.shapeOptions.color : this.options.drawError.color;
			
			L.DomUtil.setPosition(dash, dashPoint);
		}
	},

	_updateGuideColor: function (color) {
		if (this._guidesContainer) {
			for (var i = 0, l = this._guidesContainer.childNodes.length; i < l; i++) {
				this._guidesContainer.childNodes[i].style.backgroundColor = color;
			}
		}
	},

	// removes all child elements (guide dashes) from the guides container
	_clearGuides: function () {
		if (this._guidesContainer) {
			while (this._guidesContainer.firstChild) {
				this._guidesContainer.removeChild(this._guidesContainer.firstChild);
			}
		}
	},

	_getTooltipText: function () {
		var showLength = this.options.showLength,
			labelText, distanceStr;

		if (this._markers.length === 0) {
			labelText = {
				text: 'Click and drag to start drawing line.'
			};
		} else {
			distanceStr = showLength ? this._getMeasurementString() : '';
			linelength = parseInt(distanceStr.substr(0,distanceStr.length-4));
			
			if (this._markers.length === 1) {
				if(parseInt(distanceStr.substr(0,distanceStr.length-4))>1400){
					labelText = {
					text: 'Drag to continue drawing shape.',
					subtext: distanceStr+" Create a smaller cross section for better view"
					};
				}else{
				labelText = {
					text: 'Drag to continue drawing shape.',
					subtext: distanceStr
				};
				}
			} else {
				labelText = {
					text: 'Drag',
					subtext: distanceStr
				};
			}
		}
		return labelText;
	},

	_updateRunningMeasure: function (latlng, added) {
		var markersLength = this._markers.length,
			previousMarkerIndex, distance;

		if (this._markers.length === 1) {
			this._measurementRunningTotal = 0;
		} else {
			previousMarkerIndex = markersLength - (added ? 2 : 1);
			distance = latlng.distanceTo(this._markers[0].getLatLng());

			this._measurementRunningTotal += distance * (added ? 1 : -1);
		}
	},

	_getMeasurementString: function () {
		var currentLatLng = this._currentLatLng,
			previousLatLng = this._markers[0].getLatLng(),
			distance;

		// calculate the distance from the last fixed point to the mouse position
		distance = currentLatLng.distanceTo(previousLatLng);
		return this.readableDistance(distance, this.options.metric);
	},

	_showErrorTooltip: function () {
	
		this._errorShown = true;

		// Update tooltip
		this._tooltip
			.showAsError()
			.updateContent({ text: this.options.drawError.message });

		// Update shape
		this._updateGuideColor(this.options.drawError.color);
		this._crossSection.line.setStyle({ color: this.options.drawError.color });

		// Hide the error after 2 seconds
		this._clearHideErrorTimeout();
		this._hideErrorTimeout = setTimeout(L.Util.bind(this._hideErrorTooltip, this), this.options.drawError.timeout);
	},

	_hideErrorTooltip: function () {
		this._errorShown = false;

		this._clearHideErrorTimeout();

		// Revert tooltip
		this._tooltip
			.removeError()
			.updateContent(this._getTooltipText());

		// Revert shape
		this._updateGuideColor(this.options.shapeOptions.color);
		this._crossSection.line.setStyle({ color: this.options.shapeOptions.color });
	},

	_clearHideErrorTimeout: function () {
		if (this._hideErrorTimeout) {
			clearTimeout(this._hideErrorTimeout);
			this._hideErrorTimeout = null;
		}
	},

	_cleanUpShape: function () {
		if (this._markers.length > 1) {
			this._markers[this._markers.length - 1].off('click', this._finishShape, this);
		}
	},

	_fireCreatedEvent: function () {
		var poly = new L.Polyline(this._crossSection.line.getLatLngs(), this.options.shapeOptions);
		//this._map.fire('draw:created', { layer: this, layerType: 'polyline' });
		//L.Draw.Feature.prototype._fireCreatedEvent.call(this, poly);
	},
	
	readableDistance: function (distance, isMetric) {
		var distanceStr;

		if (isMetric) {
			// show metres when distance is < 1km, then show km
			if (distance > 1000) {
				distanceStr = (distance  / 1000).toFixed(2) + ' km';
			} else {
				distanceStr = Math.ceil(distance) + ' m';
			}
		} else {
			distance *= 1.09361;

			if (distance > 1760) {
				distanceStr = (distance / 1760).toFixed(2) + ' miles';
			} else {
				distanceStr = Math.ceil(distance) + ' yd';
			}
		}

		return distanceStr;
	},
	
	editAddHooks: function () {
		if (this._map) {
			if (!this._editMarkerGroup) {
				this._editInitMarkers();
			}
			this._map.addLayer(this._editMarkerGroup);
		}
	},

	editRemoveHooks: function () {
		if (this._map) {
			if(this._map.hasLayer(this._editMarkerGroup))
				this._map.removeLayer(this._editMarkerGroup);
			delete this._editMarkerGroup;
			delete this._editMarkers;
		}
	},

	editUpdateMarkers: function () {
		this._editMarkerGroup.clearLayers();
		this._editInitMarkers();
	},

	_editInitMarkers: function () {
		if (!this._editMarkerGroup) {
			this._editMarkerGroup = new L.LayerGroup();
		}
		this._editMarkers = [];

		var latlngs = this._crossSection.line.getLatLngs(),
			i, j, len, editMarker;

		// TODO refactor holes implementation in Polygon to support it here

		for (i = 0, len = latlngs.length; i < len; i++) {

			editMarker = this._editCreateMarker(latlngs[i], i);
			editMarker.on('click', this._editOnMarkerClick, this);
			this._editMarkers.push(editMarker);
		}

		var editMarkerLeft, editMarkerRight;

		for (i = 0, j = len - 1; i < len; j = i++) {
			if (i === 0 && !(L.Polygon && (this._crossSection.line instanceof L.Polygon))) {
				continue;
			}

			editMarkerLeft = this._editMarkers[j];
			editMarkerRight = this._editMarkers[i];
			endmarker1 = editMarkerLeft;
			endmarker2 = editMarkerRight;
			this._editCreateResizeMarker(editMarkerLeft,editMarkerRight);
			this._editCreateMoveMarker(editMarkerLeft, editMarkerRight);
		}
	},

	_editCreateMarker: function (latlng, index) {
		var editMarker = new L.Marker(latlng, {
			draggable: true,
			icon: new L.DivIcon({
			iconSize: new L.Point(8, 8),
			className: 'leaflet-div-icon leaflet-editing-icon'
		})
		});

		editMarker._origLatLng = latlng;
		editMarker._index = index;
		
		editMarker.on('drag', this._editOnMarkerDrag, this);
		editMarker.on('dragend', this._fireEdit, this);

		this._editMarkerGroup.addLayer(editMarker);

		return editMarker;
	},

	_editRemoveMarker: function (editMarker) {
		var i = editMarker._index;

		this._editMarkerGroup.removeLayer(editMarker);
		this._editMarkers.splice(i, 1);
		this._crossSection.line.spliceLatLngs(i, 1);
		this._updateIndexes(i, -1);

		editMarker
			.off('drag', this._editOnMarkerDrag, this)
			.off('dragend', this._fireEdit, this)
			.off('click', this._editOnMarkerClick, this);
	},

	_fireEdit: function () {
		this._crossSection.line.edited = true;
		this._crossSection.line.fire('edit');
	},

	_editOnMarkerDrag: function (e) {
		var editMarker = e.target;
		
		
		this._map.removeLayer(this._crossSection.rectangle);
		L.extend(editMarker._origLatLng, editMarker._latlng);

		/*if (marker._middleLeft) {
			marker._middleLeft.setLatLng(this._getMiddleLatLng(marker._prev, marker));
		}
		if (marker._middleRight) {
			marker._middleRight.setLatLng(this._getMiddleLatLng(marker, marker._next));
		}*/
		var map = this._map,
		    p1 = map.project([toLat(x1),toLon(y1)]),
		    p2 = map.project([toLat(x2),toLon(y2)]);
		var p4 = map.unproject(map.project([toLat(lat0),toLon(lng0)])._add(map.project([toLat(lat1),toLon(lng1)]))._divideBy(2));
		var p3 = map.unproject(p1._add(p2)._divideBy(2));
		if(editMarker._index == 2){
			if(width <= 5){
				width = Math.sqrt(Math.pow(map.project(p4).x-map.project(editMarker.getLatLng()).x,2)+Math.pow(map.project(p4).y-map.project(editMarker.getLatLng()).y,2))*initWidth/initDistance;
				
			}
			//marker.setLatLng(p3);
		}
		if(editMarker._index == 3){
			offset = [map.project(mlatlng).x - map.project(editMarker._latlng).x, map.project(mlatlng).y - map.project(editMarker._latlng).y];
			mlatlng = editMarker._latlng;
			polygonArr[0]=map.unproject([map.project(polygonArr[0]).x - offset[0],map.project(polygonArr[0]).y - offset[1]]);
			polygonArr[1]=map.unproject([map.project(polygonArr[1]).x - offset[0],map.project(polygonArr[1]).y - offset[1]]);
			this._crossSection.line.setLatLngs([polygonArr[0], polygonArr[1]]);
			/*endmarker1.setLatLng(polygonArr[0]);
			endmarker2.setLatLng(polygonArr[1]);*/
			//this.updateMarkers();
			//marker.setLatLng(p4);
		}
			lat0 =convertCoordinatesy(polygonArr[0].lat);
			lat1 =convertCoordinatesy(polygonArr[1].lat);
			lng0 =convertCoordinatesx(polygonArr[0].lng);
			lng1 =convertCoordinatesx(polygonArr[1].lng);
			length = Math.sqrt(Math.pow((lat0)-(lat1),2)+Math.pow((lng0)-(lng1),2));
			ratio1 = length/(((lat0)-(lat1)));
			ratio2 = length/(((lng0)-(lng1)));
			x1=lat1+(width/ratio2);
			y1=lng1-(width/ratio1);
			x2=lat0+(width/ratio2);
			y2=lng0-(width/ratio1);
			x3=lat0-(width/ratio2);
			y3=lng0+(width/ratio1);
			x4=lat1-(width/ratio2);
			y4=lng1+(width/ratio1);
			this._crossSection.rectangle = new L.polygon([
						[toLat(x1),toLon(y1)],
						[toLat(x2),toLon(y2)],
						[toLat(x3),toLon(y3)],
						[toLat(x4),toLon(y4)]
					]);
			this._crossSection.rectangle.addTo(this._map);
		resizemarkervar.setLatLng(p3);
		movemarkervar.setLatLng(p4);
		this._crossSection.line.redraw();
		var distance = (this.readableDistance((this._editMarkers[0]._latlng).distanceTo(this._editMarkers[1]._latlng),true));
		linelength = parseInt(distance.substr(0,distance.length-4));
	},

	_editOnMarkerClick: function (e) {
		var minPoints = L.Polygon && (this._crossSection.line instanceof L.Polygon) ? 4 : 3,
			editMarker = e.target;

		// If removing this point would create an invalid polyline/polygon don't remove
		if (this._crossSection.line.getLatLngs().length < minPoints) {
			return;
		}

		// remove the marker
		this._editRemoveMarker(editMarker);

		// update prev/next links of adjacent markers
		this._editUpdatePrevNext(editMarker._prev, editMarker._next);

		// remove ghost markers near the removed marker
		if (editMarker._middleLeft) {
			this._editMarkerGroup.removeLayer(editMarker._middleLeft);
		}
		if (editMarker._middleRight) {
			this._editMarkerGroup.removeLayer(editMarker._middleRight);
		}

		// create a ghost marker in place of the removed one
		if (editMarker._prev && marker._next) {
			this._editCreateMiddleMarker(editMarker._prev, editMarker._next);

		} else if (!editMarker._prev) {
			editMarker._next._middleLeft = null;

		} else if (!editMarker._next) {
			editMarker._prev._middleRight = null;
		}

		this._fireEdit();
	},

	_editUpdateIndexes: function (index, delta) {
		this._editMarkerGroup.eachLayer(function (editMarker) {
			if (editMarker._index > index) {
				editMarker._index += delta;
			}
		});
	},
	
	_editCreateResizeMarker: function (editMarker1, editMarker2) {
		var map = this._map,
		    p1 = map.project([toLat(x1),toLon(y1)]),
		    p2 = map.project([toLat(x2),toLon(y2)]);
		
		var p4 = map.unproject(map.project([toLat(lat0),toLon(lng0)])._add(map.project([toLat(lat1),toLon(lng1)]))._divideBy(2));
		var p3 = map.unproject(p1._add(p2)._divideBy(2));
		var editMarker = this._editCreateMarker(p3,2),
		    editOnClick,
		    editOnDragStart,
		    editOnDragEnd;
		resizemarkervar = editMarker;
		editMarker.setOpacity(0.6);
		editOnDragStart = function () {
			lat = editMarker.getLatLng().lat;
			lng = editMarker.getLatLng().lng;
			initDistance = Math.sqrt(Math.pow(map.project(p4).x-map.project(p3).x,2)+Math.pow(map.project(p4).y-map.project(p3).y,2));
			initWidth = width;
			
		};

		editOnDragEnd = function () {
			editMarker.off('dragstart', editOnDragStart, this);
			editMarker.off('dragend', editOnDragEnd, this);
			
		};

		editOnClick = function () {
			editOnDragStart.call(this);
			editOnDragEnd.call(this);
		};

		editMarker
		    .on('click', editOnClick, this)
		    .on('dragstart', editOnDragStart, this)
		    .on('dragend', editOnDragEnd, this);

		this._editMarkerGroup.addLayer(editMarker);
	},
	
	_editCreateMoveMarker: function (editMarker1, editMarker2) {
		var map = this._map;
		var p4 = map.unproject(map.project([toLat(lat0),toLon(lng0)])._add(map.project([toLat(lat1),toLon(lng1)]))._divideBy(2));
		var editMarker = this._editCreateMarker(p4,3),
		    editOnClick,
		    editOnDragStart,
		    editOnDragEnd;
		movemarkervar = editMarker;
		editMarker.setOpacity(0.6);
		editOnDragStart = function () {
			mlatlng = editMarker.getLatLng();
			mlat = editMarker.getLatLng().lat;
			mlng = editMarker.getLatLng().lng;
			
		
			
		};

		editOnDragEnd = function () {
			editMarker.off('dragstart', editOnDragStart, this);
			editMarker.off('dragend', editOnDragEnd, this);
			this._editMarkerGroup.clearLayers();
			this._editInitMarkers();
		};

		editOnClick = function () {
			editOnDragStart.call(this);
			editOnDragEnd.call(this);
		};

		editMarker
		    .on('click', editOnClick, this)
		    .on('dragstart', editOnDragStart, this)
		    .on('dragend', editOnDragEnd, this);

		this._editMarkerGroup.addLayer(editMarker);
	},

	_editUpdatePrevNext: function (editMarker1, editMarker2) {
		if (editMarker1) {
			editMarker1._next = editMarker2;
		}
		if (editMarker2) {
			editMarker2._prev = editMarker1;
		}
	},

	_editGetMiddleLatLng: function (editMarker1, editMarker2) {
		var map = this._map,
		    p1 = map.project(editMarker1.getLatLng()),
		    p2 = map.project(editMarker2.getLatLng());

		return map.unproject(p1._add(p2)._divideBy(2));
	},
	
	removeCrossSection: function() {
		if(this._map.hasLayer(this._crossSection.line))
				this._map.removeLayer(this._crossSection.line);
			if(this._map.hasLayer(this._crossSection.rectangle)){
				this._map.removeLayer(this._crossSection.rectangle);
			}
	}
});

/*global L: true */

L.KML = L.FeatureGroup.extend({
	options: {
		async: true
	},

	initialize: function(kml, options) {
		L.Util.setOptions(this, options);
		this._kml = kml;
		this._layers = {};

		if (kml) {
			this.addKML(kml, options, this.options.async);
		}
	},

	loadXML: function(url, cb, options, async) {
		if (async == undefined) async = this.options.async;
		if (options == undefined) options = this.options;

		var req = new window.XMLHttpRequest();
		req.open('GET', url, async);
		try {
			req.overrideMimeType('text/xml'); // unsupported by IE
		} catch(e) {}
		req.onreadystatechange = function() {
			if (req.readyState != 4) return;
			if(req.status == 200) cb(req.responseXML, options);
		};
		req.send(null);
	},

	addKML: function(url, options, async) {
		var _this = this;
		var cb = function(gpx, options) { _this._addKML(gpx, options) };
		this.loadXML(url, cb, options, async);
	},

	_addKML: function(xml, options) {
		var layers = L.KML.parseKML(xml);
		if (!layers || !layers.length) return;
		for (var i = 0; i < layers.length; i++)
		{
			this.fire('addlayer', {
				layer: layers[i]
			});
			this.addLayer(layers[i]);
		}
		this.latLngs = L.KML.getLatLngs(xml);
		this.fire("loaded");
	},

	latLngs: []
});

L.Util.extend(L.KML, {

	parseKML: function (xml) {
		var style = this.parseStyle(xml);
		this.parseStyleMap(xml, style);
		var el = xml.getElementsByTagName("Folder");
		var layers = [], l;
		for (var i = 0; i < el.length; i++) {
			if (!this._check_folder(el[i])) { continue; }
			l = this.parseFolder(el[i], style);
			if (l) { layers.push(l); }
		}
		el = xml.getElementsByTagName('Placemark');
		for (var j = 0; j < el.length; j++) {
			if (!this._check_folder(el[j])) { continue; }
			l = this.parsePlacemark(el[j], xml, style);
			if (l) { layers.push(l); }
		}
		return layers;
	},

	// Return false if e's first parent Folder is not [folder]
	// - returns true if no parent Folders
	_check_folder: function (e, folder) {
		e = e.parentElement;
		while (e && e.tagName !== "Folder")
		{
			e = e.parentElement;
		}
		return !e || e === folder;
	},

	parseStyle: function (xml) {
		var style = {};
		var sl = xml.getElementsByTagName("Style");

		//for (var i = 0; i < sl.length; i++) {
		var attributes = {color: true, width: true, Icon: true, href: true,
						  hotSpot: true};

		function _parse(xml) {
			var options = {};
			for (var i = 0; i < xml.childNodes.length; i++) {
				var e = xml.childNodes[i];
				var key = e.tagName;
				if (!attributes[key]) { continue; }
				if (key === 'hotSpot')
				{
					for (var j = 0; j < e.attributes.length; j++) {
						options[e.attributes[j].name] = e.attributes[j].nodeValue;
					}
				} else {
					var value = e.childNodes[0].nodeValue;
					if (key === 'color') {
						options.opacity = parseInt(value.substring(0, 2), 16) / 255.0;
						options.color = "#" + value.substring(6, 8) + value.substring(4, 6) + value.substring(2, 4);
					} else if (key === 'width') {
						options.weight = value;
					} else if (key === 'Icon') {
						ioptions = _parse(e);
						if (ioptions.href) { options.href = ioptions.href; }
					} else if (key === 'href') {
						options.href = value;
					}
				}
			}
			return options;
		}

		for (var i = 0; i < sl.length; i++) {
			var e = sl[i], el;
			var options = {}, poptions = {}, ioptions = {};
			el = e.getElementsByTagName("LineStyle");
			if (el && el[0]) { options = _parse(el[0]); }
			el = e.getElementsByTagName("PolyStyle");
			if (el && el[0]) { poptions = _parse(el[0]); }
			if (poptions.color) { options.fillColor = poptions.color; }
			if (poptions.opacity) { options.fillOpacity = poptions.opacity; }
			el = e.getElementsByTagName("IconStyle");
			if (el && el[0]) { ioptions = _parse(el[0]); }
			if (ioptions.href) {
				// save anchor info until the image is loaded
				options.icon = new L.KMLIcon({
					iconUrl: ioptions.href,
					shadowUrl: null,
					iconAnchorRef: {x: ioptions.x, y: ioptions.y},
					iconAnchorType:	{x: ioptions.xunits, y: ioptions.yunits}
				});
			}
			style['#' + e.getAttribute('id')] = options;
		}
		return style;
	},
	
	parseStyleMap: function (xml, existingStyles) {
		var sl = xml.getElementsByTagName("StyleMap");
		
		for (var i = 0; i < sl.length; i++) {
			var e = sl[i], el;
			var smKey, smStyleUrl;
			
			el = e.getElementsByTagName("key");
			if (el && el[0]) { smKey = el[0].textContent; }
			el = e.getElementsByTagName("styleUrl");
			if (el && el[0]) { smStyleUrl = el[0].textContent; }
			
			if (smKey=='normal')
			{
				existingStyles['#' + e.getAttribute('id')] = existingStyles[smStyleUrl];
			}
		}
		
		return;
	},

	parseFolder: function (xml, style) {
		var el, layers = [], l;
		el = xml.getElementsByTagName('Folder');
		for (var i = 0; i < el.length; i++) {
			if (!this._check_folder(el[i], xml)) { continue; }
			l = this.parseFolder(el[i], style);
			if (l) { layers.push(l); }
		}
		el = xml.getElementsByTagName('Placemark');
		for (var j = 0; j < el.length; j++) {
			if (!this._check_folder(el[j], xml)) { continue; }
			l = this.parsePlacemark(el[j], xml, style);
			if (l) { layers.push(l); }
		}
		if (!layers.length) { return; }
		if (layers.length === 1) { return layers[0]; }
		return new L.FeatureGroup(layers);
	},

	parsePlacemark: function (place, xml, style) {
		var i, j, el, options = {};
		el = place.getElementsByTagName('styleUrl');
		for (i = 0; i < el.length; i++) {
			var url = el[i].childNodes[0].nodeValue;
			for (var a in style[url])
			{
				// for jshint
				if (true)
				{
					options[a] = style[url][a];
				}
			}
		}
		var layers = [];

		var parse = ['LineString', 'Polygon', 'Point'];
		for (j in parse) {
			// for jshint
			if (true)
			{
				var tag = parse[j];
				el = place.getElementsByTagName(tag);
				for (i = 0; i < el.length; i++) {
					var l = this["parse" + tag](el[i], xml, options);
					if (l) { layers.push(l); }
				}
			}
		}

		if (!layers.length) {
			return;
		}
		var layer = layers[0];
		if (layers.length > 1) {
			layer = new L.FeatureGroup(layers);
		}

		var name, descr = "";
		el = place.getElementsByTagName('name');
		if (el.length && el[0].childNodes.length) {
			name = el[0].childNodes[0].nodeValue;
		}
		el = place.getElementsByTagName('description');
		for (i = 0; i < el.length; i++) {
			for (j = 0; j < el[i].childNodes.length; j++) {
				descr = descr + el[i].childNodes[j].nodeValue;
			}
		}

		if (name) {
			layer.bindPopup("<h2>" + name + "</h2>" + descr);
		}

		return layer;
	},

	parseCoords: function (xml) {
		var el = xml.getElementsByTagName('coordinates');
		return this._read_coords(el[0]);
	},

	parseLineString: function (line, xml, options) {
		var coords = this.parseCoords(line);
		if (!coords.length) { return; }
		return new L.Polyline(coords, options);
	},

	parsePoint: function (line, xml, options) {
		var el = line.getElementsByTagName('coordinates');
		if (!el.length) {
			return;
		}
		var ll = el[0].childNodes[0].nodeValue.split(',');
		return new L.KMLMarker(new L.LatLng(ll[1], ll[0]), options);
	},

	parsePolygon: function (line, xml, options) {
		var el, polys = [], inner = [], i, coords;
		el = line.getElementsByTagName('outerBoundaryIs');
		for (i = 0; i < el.length; i++) {
			coords = this.parseCoords(el[i]);
			if (coords) {
				polys.push(coords);
			}
		}
		el = line.getElementsByTagName('innerBoundaryIs');
		for (i = 0; i < el.length; i++) {
			coords = this.parseCoords(el[i]);
			if (coords) {
				inner.push(coords);
			}
		}
		if (!polys.length) {
			return;
		}
		if (options.fillColor) {
			options.fill = true;
		}
		if (polys.length === 1) {
			return new L.Polygon(polys.concat(inner), options);
		}
		return new L.MultiPolygon(polys, options);
	},

	getLatLngs: function (xml) {
		var el = xml.getElementsByTagName('coordinates');
		var coords = [];
		for (var j = 0; j < el.length; j++) {
			// text might span many childNodes
			coords = coords.concat(this._read_coords(el[j]));
		}
		return coords;
	},

	_read_coords: function (el) {
		var text = "", coords = [], i;
		for (i = 0; i < el.childNodes.length; i++) {
			text = text + el.childNodes[i].nodeValue;
		}
		text = text.split(/[\s\n]+/);
		for (i = 0; i < text.length; i++) {
			var ll = text[i].split(',');
			if (ll.length < 2) {
				continue;
			}
			coords.push(new L.LatLng(ll[1], ll[0]));
		}
		return coords;
	}

});

L.KMLIcon = L.Icon.extend({

	createIcon: function () {
		var img = this._createIcon('icon');
		img.onload = function () {
			var i = img;
			this.style.width = i.width + 'px';
			this.style.height = i.height + 'px';

			if (this.anchorType.x === 'UNITS_FRACTION' || this.anchorType.x === 'fraction') {
				img.style.marginLeft = (-this.anchor.x * i.width) + 'px';
			}
			if (this.anchorType.y === 'UNITS_FRACTION' || this.anchorType.x === 'fraction') {
				img.style.marginTop  = (-(1 - this.anchor.y) * i.height) + 'px';
			}
			this.style.display = "";
		};
		return img;
	},

	_setIconStyles: function (img, name) {
		L.Icon.prototype._setIconStyles.apply(this, [img, name])
		// save anchor information to the image
		img.anchor = this.options.iconAnchorRef;
		img.anchorType = this.options.iconAnchorType;
	}
});


L.KMLMarker = L.Marker.extend({
	options: {
		icon: new L.KMLIcon.Default()
	}
});


/*
 * L.LatLngUtil contains different utility functions for LatLngs.
 */

L.LatLngUtil = {
	// Clones a LatLngs[], returns [][]
	cloneLatLngs: function (latlngs) {
		var clone = [];
		for (var i = 0, l = latlngs.length; i < l; i++) {
			clone.push(this.cloneLatLng(latlngs[i]));
		}
		return clone;
	},

	cloneLatLng: function (latlng) {
		return L.latLng(latlng.lat, latlng.lng);
	}
};
L.Tooltip = L.Class.extend({
	initialize: function (map) {
		this._map = map;
		this._popupPane = map._panes.popupPane;

		this._container = L.DomUtil.create('div', 'leaflet-draw-tooltip', this._popupPane);
		this._singleLineLabel = false;
	},

	dispose: function () {
		if (this._container) {
			this._popupPane.removeChild(this._container);
			this._container = null;
		}
	},

	updateContent: function (labelText) {
		if (!this._container) {
			console.log("hello");
			return this;
		}
		labelText.subtext = labelText.subtext || '';

		// update the vertical position (only if changed)
		if (labelText.subtext.length === 0 && !this._singleLineLabel) {
			L.DomUtil.addClass(this._container, 'leaflet-draw-tooltip-single');
			this._singleLineLabel = true;
		}
		else if (labelText.subtext.length > 0 && this._singleLineLabel) {
			L.DomUtil.removeClass(this._container, 'leaflet-draw-tooltip-single');
			this._singleLineLabel = false;
		}

		this._container.innerHTML =
			(labelText.subtext.length > 0 ? '<span class="leaflet-draw-tooltip-subtext">' + labelText.subtext + '</span>' + '<br />' : '') +
			'<span>' + labelText.text + '</span>';
		
		return this;
	},

	updatePosition: function (latlng) {
		var pos = this._map.latLngToLayerPoint(latlng),
			tooltipContainer = this._container;

		if (this._container) {
			tooltipContainer.style.visibility = 'inherit';
			L.DomUtil.setPosition(tooltipContainer, pos);
		}

		return this;
	},

	showAsError: function () {
		if (this._container) {
			L.DomUtil.addClass(this._container, 'leaflet-error-draw-tooltip');
		}
		return this;
	},

	removeError: function () {
		if (this._container) {
			L.DomUtil.removeClass(this._container, 'leaflet-error-draw-tooltip');
		}
		return this;
	}
});
function loadCount(click){
	if(($('#date-1-y').val()=="null"||$('#date-2-y').val()=="null")&&click==0){
		$("#error-date").html("<p style='color:red'>Select the years</p>");
		return;
	}
	else{
		$("#error-date").html("");
	}
	month1 = parseInt($('#date-1-m').val()-1);
	year1 = parseInt($('#date-1-y').val())-60;
	month2 = parseInt($('#date-2-m').val()-1);
	year2 = parseInt($('#date-2-y').val())-60;
	if((parseInt(year2)*12)+parseInt(month2)<=(parseInt(year1)*12)+parseInt(month1)){
		$("#error-date").html("<p style='color:red'>Select a valid date range</p>");
		return;
	}
	else{
		$("#error-date").html("");
	}
	if(click==0)
	window.open("?mag="+binarySearch(0,100)+"&startdate="+(parseInt(year1)+1960)+"-"+(parseInt(month1)+1)+"-1&enddate="+(parseInt(year2)+1960)+"-"+(parseInt(month2)+1)+"-1","_self");
	else
	$("#magnitude-search").html("<p>Calculated magnitude cutoff : </p><p style='color:green'>"+binarySearch(0,100)+"</p>");
};
function binarySearch(mag,max){
		if(mag<max){
			var count = 0;
			count=parseInt(magarray[parseInt(mag)][(parseInt(year2)*12)+parseInt(month2)])-parseInt(magarray[parseInt(mag)][(parseInt(year1)*12)+parseInt(month1)]);
			if(parseInt(count)>20000){
				return binarySearch(parseInt(mag)+((max-parseInt(mag))/2),max);
			}
			else if(parseInt(count)<15000 && mag!=0){
				return binarySearch(parseInt(mag)-((max-parseInt(mag))/2),mag);
			}
			else{
				return parseInt(mag)/10;
			}
		}
}

;
;/*
The 2D map has coordinates ranging from -180 to +180 from left to right and from +90 to -90 from top to bottom.
The 3D map projection ranges 64x64 units. The projection shows only 4x4 units of this area which is centred at 0,0,0.
This file finds the location of the point in this 3D projection corresponding to its latitude and longitude values. 
*/
function convertCoordinatesx(x){
	
	//converting the coordinates into new coordinate system
	x=parseFloat(x);
	x=((x+180)*64)/360;
	return x;
}
function convertCoordinatesy(y){
	
	//converting the coordinates into new coordinate system
	y = parseFloat(y);
	y = y*(Math.PI/180);
	y= (1 - (Math.log(Math.tan((y/2)+(Math.PI/4))) / Math.PI))*32;
	return y;
}
function toLon(x){
	x=parseFloat(x);
	x=(x*360/64)-180;
	return x;
}
function toLat(y){
y = parseFloat(y);
	y =2*(Math.atan(Math.pow(Math.E,(1-(y/32))*Math.PI))-(Math.PI/4));
	y=y*180/Math.PI;
	return y;
}
;var map2D = (function () {

    //The map object with all the variables of current map being shown
    var map = {

        leafletMap: L.map('map'),

        crossSection: {},

        parameters: {
            mag: getURLParameter("mag"),
            startdate: getURLParameter("startdate"),
            enddate: getURLParameter("enddate"),

            defaultInit: function () {
                var d = new Date();
                if (this.mag == undefined) {
                    this.mag = 5;
                }
                if (this.startdate == undefined) {
                    this.startdate = "2009/1/1";
                }
                if (this.enddate == undefined) {
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
            baseLayer2: L.tileLayer('http://otile1.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png', {}),
            baseLayer1: L.tileLayer('http://{s}.tiles.mapbox.com/v3/bclc-apec.map-rslgvy56/{z}/{x}/{y}.png', {})
        },

        drawnItems: new L.FeatureGroup(), //features drawn on the map (constitute the cross-section)

        earthquakes: {
            circles: new Array(), // Array of earthquake markers
            time: new Array(), // time of occurrence of corresponding earthquakes
            depth: new Array() // Array of depths of corresponding earthquakes
        },

        array: new Array(),
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

            this.script.src = 'http://comcat.cr.usgs.gov/fdsnws/event/1/query?starttime=' + map.parameters.startdate + '%0000:00:00&minmagnitude=' + map.parameters.mag + '&format=geojson&callback=eqfeed_callback&endtime=' + map.parameters.enddate + '%0000:00:00&orderby=time-asc';
            document.getElementsByTagName('body')[0].appendChild(this.script);
            window.eqfeed_callback = function (results) {

                map.values.size = results.features.length;

                for (var i = 0; i < map.values.size; i++) {
                    map.earthquakes.circles[i] = L.geoJson(results.features[i], {
                        pointToLayer: function (feature, latlng) {
                            return L.circleMarker(latlng, {
                                radius: results.features[i].properties.mag,
                                fillColor: "#" + rainbow.colourAt(results.features[i].properties.mag),
                                color: "#000",
                                weight: 1,
                                opacity: 1,
                                fillOpacity: 1
                            });
                        }
                    }).bindPopup("Place: <b>" + results.features[i].properties.place + "</b></br>Magnitude : <b>" + results.features[i].properties.mag + "</b></br>Time : " + timeConverter(results.features[i].properties.time) + "</br>Depth : " + results.features[i].geometry.coordinates[2] + " km");

                    map.earthquakes.time[i] = results.features[i].properties.time
                    map.earthquakes.depth[i] = results.features[i].geometry.coordinates[2];
                    if (map.earthquakes.depth[i] > map.values.maxdepth) map.values.maxdepth = map.earthquakes.depth[i];
                    if (map.earthquakes.depth[i] < map.values.mindepth) map.values.mindepth = map.earthquakes.depth[i];

                    // add events to timeline
                    if (i > 0) {
                        controller.timeLine.append(TweenLite.delayedCall(20 * ((results.features[i].properties.time - results.features[i - 1].properties.time) / 1000000000), map.mapAdder, [i.toString()]));
                    } else {
                        controller.timeLine.append(TweenLite.delayedCall(0, map.mapAdder, [i.toString()]));
                    }
                }

                rainbow.setNumberRange(map.values.mindepth, map.values.maxdepth);
                map.values.timediff = results.features[map.values.size - 1].properties.time - results.features[0].properties.time;
                map.parameters.starttime = results.features[0].properties.time;

                $("#slider").slider({
                    value: 0,
                    range: "min",
                    min: 0,
                    max: map.values.timediff,
                    slide: function (event, ui) {
                        $("#date").html(timeConverter(map.parameters.starttime));
                        controller.timeLine.pause();
                        controller.timeLine.progress(ui.value / (map.values.timediff));
                    }
                })

                $("#info").html("</br></br>total earthquakes : " + map.values.size + "</br>minimum depth : " + map.values.mindepth + " km</br>maximum depth : " + map.values.maxdepth + " km</br></br></br><div class='ui-body ui-body-a'><p><a href='http://github.com/gizmoabhinav/Seismic-Eruptions'>Link to the project</a></p></div>");
                $("#startdate").html("Start date : " + timeConverter(map.parameters.startdate));
                $("#enddate").html("End date : " + timeConverter(map.parameters.enddate));
                $("#magcutoff").html("Cutoff magnitude : " + map.parameters.mag);
            }
            loadCountFile();

        }
    };


    function getURLParameter(name) {
        return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [, ""])[1].replace(/\+/g, '%20')) || null
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
            magarray = new Array();
            for (var i = 99; i >= 0; i--) {
                magarray[i] = new Array();
                for (var j = 0; j < length / 102; j++) {
                    if (magarray[i][j] != undefined) magarray[i][j] = parseInt(array[(j * 102) + 2 + i]) + parseInt(magarray[i][j]);
                    else magarray[i][j] = parseInt(array[(j * 102) + 2 + i]);
                    if (j + 1 < length / 102) magarray[i][j + 1] = parseInt(magarray[i][j]);
                    if (i < 99) magarray[i][j] = parseInt(magarray[i + 1][j]) + parseInt(magarray[i][j]);
                }
            }
            console.log(magarray);
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

        map.layers.baseLayer1.addTo(map.leafletMap);

        map.leafletMap.fitBounds([
            [50, 40],
            [-20, -40]
        ]);
        map.leafletMap.setMaxBounds([
            [-90, 180],
            [90, -180]
        ]);

        controller.timeLine.timeScale(controller.speed);
        controller.timeLine.pause();
        controller.initController();



        $.mobile.loading('hide');
        setTimeout(function () {
            map.leafletMap.invalidateSize();
        }, 1);
        controller.timeLine.resume();


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

/*
RainbowVis-JS 
Released under Eclipse Public License - v 1.0
*/

function Rainbow()
{
	var gradients = null;
	var minNum = 0;
	var maxNum = 100;
	var colours = ['ff0000', 'ffff00', '00ff00', '0000ff']; 
	setColours(colours);
	
	function setColours (spectrum) 
	{
		if (spectrum.length < 2) {
			throw new Error('Rainbow must have two or more colours.');
		} else {
			var increment = (maxNum - minNum)/(spectrum.length - 1);
			var firstGradient = new ColourGradient();
			firstGradient.setGradient(spectrum[0], spectrum[1]);
			firstGradient.setNumberRange(minNum, minNum + increment);
			gradients = [ firstGradient ];
			
			for (var i = 1; i < spectrum.length - 1; i++) {
				var colourGradient = new ColourGradient();
				colourGradient.setGradient(spectrum[i], spectrum[i + 1]);
				colourGradient.setNumberRange(minNum + increment * i, minNum + increment * (i + 1)); 
				gradients[i] = colourGradient; 
			}

			colours = spectrum;
			return this;
		}
	}

	this.setColors = this.setColours;

	this.setSpectrum = function () 
	{
		setColours(arguments);
		return this;
	}

	this.setSpectrumByArray = function (array)
	{
		setColours(array);
        return this;
	}

	this.colourAt = function (number)
	{
		if (isNaN(number)) {
			throw new TypeError(number + ' is not a number');
		} else if (gradients.length === 1) {
			return gradients[0].colourAt(number);
		} else {
			var segment = (maxNum - minNum)/(gradients.length);
			var index = Math.min(Math.floor((Math.max(number, minNum) - minNum)/segment), gradients.length - 1);
			return gradients[index].colourAt(number);
		}
	}

	this.colorAt = this.colourAt;

	this.setNumberRange = function (minNumber, maxNumber)
	{
		if (maxNumber > minNumber) {
			minNum = minNumber;
			maxNum = maxNumber;
			setColours(colours);
		} else {
			throw new RangeError('maxNumber (' + maxNumber + ') is not greater than minNumber (' + minNumber + ')');
		}
		return this;
	}
}

function ColourGradient() 
{
	var startColour = 'ff0000';
	var endColour = '0000ff';
	var minNum = 0;
	var maxNum = 100;

	this.setGradient = function (colourStart, colourEnd)
	{
		startColour = getHexColour(colourStart);
		endColour = getHexColour(colourEnd);
	}

	this.setNumberRange = function (minNumber, maxNumber)
	{
		if (maxNumber > minNumber) {
			minNum = minNumber;
			maxNum = maxNumber;
		} else {
			throw new RangeError('maxNumber (' + maxNumber + ') is not greater than minNumber (' + minNumber + ')');
		}
	}

	this.colourAt = function (number)
	{
		return calcHex(number, startColour.substring(0,2), endColour.substring(0,2)) 
			+ calcHex(number, startColour.substring(2,4), endColour.substring(2,4)) 
			+ calcHex(number, startColour.substring(4,6), endColour.substring(4,6));
	}
	
	function calcHex(number, channelStart_Base16, channelEnd_Base16)
	{
		var num = number;
		if (num < minNum) {
			num = minNum;
		}
		if (num > maxNum) {
			num = maxNum;
		} 
		var numRange = maxNum - minNum;
		var cStart_Base10 = parseInt(channelStart_Base16, 16);
		var cEnd_Base10 = parseInt(channelEnd_Base16, 16); 
		var cPerUnit = (cEnd_Base10 - cStart_Base10)/numRange;
		var c_Base10 = Math.round(cPerUnit * (num - minNum) + cStart_Base10);
		return formatHex(c_Base10.toString(16));
	}

	formatHex = function (hex) 
	{
		if (hex.length === 1) {
			return '0' + hex;
		} else {
			return hex;
		}
	} 
	
	function isHexColour(string)
	{
		var regex = /^#?[0-9a-fA-F]{6}$/i;
		return regex.test(string);
	}

	function getHexColour(string)
	{
		if (isHexColour(string)) {
			return string.substring(string.length - 6, string.length);
		} else {
			var colourNames =
			[
				['red', 'ff0000'],
				['lime', '00ff00'],
				['blue', '0000ff'],
				['yellow', 'ffff00'],
				['orange', 'ff8000'],
				['aqua', '00ffff'],
				['fuchsia', 'ff00ff'],
				['white', 'ffffff'],
				['black', '000000'],
				['gray', '808080'],
				['grey', '808080'],
				['silver', 'c0c0c0'],
				['maroon', '800000'],
				['olive', '808000'],
				['green', '008000'],
				['teal', '008080'],
				['navy', '000080'],
				['purple', '800080']
			];
			for (var i = 0; i < colourNames.length; i++) {
				if (string.toLowerCase() === colourNames[i][0]) {
					return colourNames[i][1];
				}
			}
			throw new Error(string + ' is not a valid colour.');
		}
	}
}

;