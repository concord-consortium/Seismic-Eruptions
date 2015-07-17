module.exports =
class Utils
  # n is a ratio between min and max.
  # returns the value between min and max that sits at that ratio
  @expandNorm: (n, min, max)->
    n * (max - min) + min

  # returns the ratio that value sits between min and max
  @contractNorm: (value, min, max)->
    (value - min) / (max - min)

  # Formats a given date number as MMM DD, YYYY
  @dateFormat: (dateNumber)->
    date = new Date(dateNumber)
    return "#{Utils.getMonth(date.getMonth())} #{date.getDate()}, #{date.getFullYear()}"

  @getMonth: (monthNumber)->
    switch monthNumber
      when 0 then "Jan"
      when 1 then "Feb"
      when 2 then "Mar"
      when 3 then "Apr"
      when 4 then "May"
      when 5 then "Jun"
      when 6 then "Jul"
      when 7 then "Aug"
      when 8 then "Sep"
      when 9 then "Oct"
      when 10 then "Nov"
      when 11 then "Dec"
