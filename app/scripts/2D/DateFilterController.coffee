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

  @MIN_DATE: (new Date(1900, 0)).valueOf()
  @MAX_DATE: Date.now()

  constructor: ()->
    super
    @startDate = new Date(1960, 0).valueOf()
    @endDate = DateFilterController.MAX_DATE
    @animatedEndDate = DateFilterController.MAX_DATE

    @sessionController = SessionController

    # Create and hook up a playback controller
    @playbackController = PlaybackController

    @playbackController.subscribe "update", (progress)=>
      @animatedEndDate = progress * (@endDate - @startDate) + @startDate
      @limitDatesJustInCase()
      @postControllerChanges()
      @updatePlaybackSliderTextOnly()
      @updateSession()

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
      # Update playback to reflect data changes
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()
      @updateSession()

    @dateRangeSlider.subscribe "update-end", (end)=>
      @endDate = (new Date(end, 11, 31)).valueOf()
      # Update playback to reflect data changes
      @animatedEndDate = Infinity
      @limitDatesJustInCase()
      @postControllerChanges()
      @updateDateRange()
      @updatePlaybackSlider()
      @updateSession()

    # When requested, update
    @listen "request-update", @postControllerChanges

    # React to the changing session
    @sessionController.subscribe "update", (session)=>
      {
        @startDate
        @animatedEndDate
        @endDate
      } = session
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
      @animatedEndDate
      @endDate
    }


  # Limits the animated end date to fit in the start and end dates
  limitDatesJustInCase: ()->
    @endDate = Math.min(@endDate, DateFilterController.MAX_DATE)
    @startDate = Math.max(@startDate, DateFilterController.MIN_DATE)
    @animatedEndDate = Math.round(Math.min(Math.max(@animatedEndDate, @startDate), @endDate))

  # Tells everyone that the filter has changed
  postControllerChanges: ()->
    @post "update", {
      startDate: @startDate
      endDate: @animatedEndDate
    }

  updatePlaybackSliderTextOnly: ()->
    # Set the playhead text
    @playbackController.tell "set-text",
      "#{DataFormatter.formatDate(@animatedEndDate)}"

  updatePlaybackSlider: ()->
    # Set the playhead depending on new start and end ranges
    @playbackController.tell "set",
      (@animatedEndDate - @startDate) / (@endDate - @startDate)

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
    @dateRangeSlider.tell "set-text",
        "#{startYear} and #{endYear}"
    @dateRangeSlider.tell "set", startYear, endYear
