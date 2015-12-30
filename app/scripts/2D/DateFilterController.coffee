###
A class to manage the date filter, connecting the data filter to the
# UI date range slider, playback slider, and the animation of date range
###
NNode = require("./NNode")
PlaybackController = require("./PlaybackController")
DateRangeSliderUI = require("./DateRangeSliderUI")
DataFormatter = require("./DataFormatter")
SessionController = require("./SessionController")

module.exports = new
class DateFilterController extends NNode


  constructor: ()->
    super

    @minDate = (new Date(1900, 0)).valueOf()
    @maxDate = Date.now()

    @startDate = new Date(1958, 0).valueOf()
    @endDate = @maxDate
    @sliderDate = @maxDate

    @sessionController = SessionController

    # Create and hook up a playback controller
    @playbackController = PlaybackController

    @playbackController.subscribe "update", (progress)=>
      @sliderDate = progress * (@endDate - @startDate) + @startDate
      @limitDatesJustInCase()
      @postControllerChanges()
      @updatePlaybackSliderTextOnly()
      @updateSession()

    # Create and hook up a the UI date range
    @dateRangeSlider = DateRangeSliderUI

    @dateRangeSlider.subscribe "update-start", (start)=>
      @startDate = (new Date(start, 0)).valueOf()
      # Update playback to reflect data changes
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()
      @updateSession()

    @dateRangeSlider.subscribe "update-end", (end)=>
      @endDate = (new Date(end, 11, 31)).valueOf()
      # Update playback to reflect data changes
      @sliderDate = Infinity
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()
      @updateSession()

    # When requested, update
    @listen "request-update", @postControllerChanges

    # React to the changing session
    @sessionController.subscribe "update", (updates)=>
      needsUpdating = no
      if "startDate" of updates
        {@startDate} = updates
        needsUpdating = yes
      if "sliderDate" of updates
        {@sliderDate} = updates
        needsUpdating = yes
      if "endDate" of updates
        {@endDate} = updates
        needsUpdating = yes
      if "minDate" of updates
        {@minDate} = updates
        needsUpdating = yes
      if "maxDate" of updates
        {@maxDate} = updates
        needsUpdating = yes
      if needsUpdating
        @limitDatesJustInCase()
        @postControllerChanges()
        @updateDateRange()
        @updatePlaybackSlider()

    @updatePlaybackSlider()
    @updateDateRange()
    @updateSession()

  updateSession: ()->
    @sessionController.tell "append", {
      @startDate
      @sliderDate
      @endDate
      @minDate
      @maxDate
    }


  # Limits the animated end date to fit in the start and end dates
  limitDatesJustInCase: ()->
    @minYear = Math.min(@minYear, @maxYear)
    @endDate = Math.min(@endDate, @maxDate)
    @startDate = Math.max(@startDate, @minDate)
    @sliderDate = Math.round(Math.min(Math.max(@sliderDate, @startDate), @endDate))

  # Tells everyone that the filter has changed
  postControllerChanges: ()->
    @post "update", {
      @startDate
      endDate: @sliderDate
    }

  updatePlaybackSliderTextOnly: ()->
    # Set the playhead text
    @playbackController.tell "set-text",
      "#{DataFormatter.formatDate(@sliderDate)}"

  updatePlaybackSlider: ()->
    # Set the playhead depending on new start and end ranges
    @playbackController.tell "set",
      (@sliderDate - @startDate) / (@endDate - @startDate) or 0

    # Set the playhead step (1/#days between start and end)
    msBetweenStartAndEnd = @endDate - @startDate
    msPerDay = 1000 * 60 * 60 * 24
    days = (msBetweenStartAndEnd / msPerDay) | 0
    @playbackController.tell "set-step", 1 / days

    @updatePlaybackSliderTextOnly()

  # Set the date range text
  updateDateRange: ()->
    startYear = (new Date(@startDate)).getFullYear()
    endYear = (new Date(@endDate)).getFullYear()
    @dateRangeSlider.tell "configure", {
      minYear: (new Date(@minDate)).getFullYear()
      maxYear: (new Date(@maxDate)).getFullYear()
      yearStep: 1
    }
    @dateRangeSlider.tell "set-text",
        "#{startYear} and #{endYear}"
    @dateRangeSlider.tell "set", startYear, endYear
