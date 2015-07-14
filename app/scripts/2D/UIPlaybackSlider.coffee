NNode = require("./NNode")


module.exports =
class UIPlaybackSlider extends NNode

  constructor: ()->
    super
    $(document).ready ()=>
      # Jump through some hoops because jQuery mobile
      vanillaSlider = """<input id="slider" name="slider" type="range" min="0"
        max="1" step="0.00001" value="0" style="display:none;"
        data-theme="b" data-track-theme="b">"""

      $("#slider-wrapper").html(vanillaSlider)

      @slider = $("#slider")
      @slider.slider {
        min: 0
        max: 1
        step: 0.00001
        slideStart: ()=>
          @tellOthers "playback-set", @slider.val()
        slideStop: ()=>
          @tellOthers "playback-set", @slider.val()
      }
      @listen "playback-update", (progress)=>
        @slider.val(progress).slider("refresh")
