###
A class to manage the date filter, connecting the data filter to the
# UI date range slider, playback slider, and the animation of date range
###
NNode = require("./NNode")
PlaybackController = require("./PlaybackController")
DateRangeSliderUI = require("./DateRangeSliderUI")
Utils = require("./Utils")

module.exports = new
class DateFilterController extends NNode

  @MIN_DATE: (new Date(1900, 0)).valueOf()
  @MAX_DATE: Date.now()

  constructor: ()->
    super
    @startDate = new Date(1960, 0).valueOf()
    @endDate = DateFilterController.MAX_DATE
    @animatedEndDate = DateFilterController.MAX_DATE

    # Create and hook up a playback controller
    @playbackController = PlaybackController

    @playbackController.subscribe "update", (progress)=>
      @animatedEndDate = Utils.expandNorm(progress, @startDate, @endDate)
      @postControllerChanges()
      @updatePlaybackSliderTextOnly()

    # Create and hook up a the UI date range
    @dateRangeSlider = DateRangeSliderUI
    @dateRangeSlider.tell "configure", {
      startYear: (new Date(DateFilterController.MIN_DATE)).getFullYear()
      endYear: (new Date(DateFilterController.MAX_DATE)).getFullYear()
      yearStep: 1
      initialStartYear: (new Date(@startDate)).getFullYear()
      initialEndYear: (new Date(@endDate)).getFullYear()
    }

    @dateRangeSlider.subscribe "update-start", (start)=>
      @startDate = (new Date(start, 0)).valueOf()
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()

    @dateRangeSlider.subscribe "update-end", (end)=>
      @endDate = (new Date(end, 11, 31)).valueOf()
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()

    @updatePlaybackSlider()
    @updateDateRange()

    # When requested, update
    @listen "request-update", @postControllerChanges

  # Limits the animated end date to fit in the start and end dates
  limitDatesJustInCase: ()->
    @endDate = Math.min(@endDate, DateFilterController.MAX_DATE)
    @animatedEndDate = Math.min(Math.max(@animatedEndDate, @startDate), @endDate)

  # Tells everyone that the filter has changed
  postControllerChanges: ()->
    @post "update", {
      startDate: @startDate
      endDate: @animatedEndDate
    }

  updatePlaybackSliderTextOnly: ()->
    # Set the playhead text
    @playbackController.tell "set-text",
      "#{Utils.dateFormat(@animatedEndDate)}"

  updatePlaybackSlider: ()->
    # Set the playhead depending on new start and end ranges
    @playbackController.tell "set",
      Utils.contractNorm(@animatedEndDate, @startDate, @endDate)

    # Set the playhead step (1/#days between start and end)
    msBetweenStartAndEnd = @endDate - @startDate
    msPerDay = 1000 * 60 * 60 * 24
    days = (msBetweenStartAndEnd / msPerDay) | 0
    @playbackController.tell "set-step", 1 / days

    @updatePlaybackSliderTextOnly()

  # Set the date range text
  updateDateRange: ()->
    @dateRangeSlider.tell "set-text",
        "#{(new Date(@startDate)).getFullYear()} and #{(new Date(@endDate)).getFullYear()}"
