class CustomPolyline extends L.Draw.Polyline
  # Override some methods so we can support only drawing a single line segment

  # TODO Do we need to custom-support touch events?
  # addHooks: ->
  #   super
  #   @_mouseMarker.on('touchstart', @_onMouseDown, @)

  _onMouseUp: (e) ->
    super

    if @_markers?.length is 2
      @_finishShape()

module.exports = CustomPolyline
