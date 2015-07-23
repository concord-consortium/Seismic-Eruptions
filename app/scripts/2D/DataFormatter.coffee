###
A class that contains helper methods to determine how earthquake data is formatted
in terms of depth --> color and magnitude --> radius
###

# Not sure if a local variable is the best place for the rainbow...
rainbow = new Rainbow()

monthArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

module.exports =
class DataFormatter
  @MAX_DEPTH: 700

  @depthToColor: (depth)->
    rainbow.setNumberRange(0, DataFormatter.MAX_DEPTH)
    return "##{rainbow.colourAt(depth)}"

  @magnitudeToRadius: (magnitude)->
    return 0.9 * Math.pow(1.5, (magnitude - 1))

  @formatMagnitude: (magnitude)->
    return magnitude.toFixed(1)

  # Formats a given date number as MMM DD, YYYY
  @formatDate: (dateNumber)->
    date = new Date(dateNumber)
    return "#{monthArray[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()}"
