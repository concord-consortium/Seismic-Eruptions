class MagnitudeSearch
  loadMagArray: ->
    return new Promise (resolve, reject)=>
      $.get 'count.txt', (data) =>
        arr = data.split(',')
        @magarray = []
        for i in [99..0]
          magarray[i] = []
          for j in [0...(arr.length / 102)] by 1
            if @magarray[i][j]?
              magarray[i][j] = parseInt(arr[(j * 102) + 2 + i]) + magarray[i][j]
            else
              magarray[i][j] = parseInt(arr[(j * 102) + 2 + i])
            if (j + 1) < (arr.length / 102)
              magarray[i][j + 1] = parseInt(magarray[i][j])
            if i < 99
              magarray[i][j] = parseInt(magarray[i + 1][j]) + magarray[i][j]

        resolve()

  loadCount: (click) ->
    $("#error-date").html("")
    unless @magArray?
      @loadMagArray().then =>
        @loadCount(click)

    @d1 = {
      year: $('#date-1-y').val()
      month: $('#date-1-m').val()
    }

    @d2 = {
      year: $('#date-2-y').val()
      month: $('#date-2-m').val()
    }

    if click is 0 and !(@d1.year? and @d2.year?)
      $("#error-date").html("<p style='color:red'>Select the years</p>")
      return

    @d1.year = @d1.year - 60
    @d1.month = @d1.month - 1
    @d2.year = @d2.year - 60
    @d1.month = @d2.month - 1

    if @d2.year * 12 + @d2.month <= @d1.year * 12 + @d1.month
      $("#error-date").html("<p style='color:red'>Select a valid date range</p>")
      return

    if click is 0
      window.open("?mag=#{@_binarySearch(0, 100)}&startdate=#{(@d1.year+1960)}-#{(@d1.month+1)}-1&\
        enddate=#{(@d2.year+1960)}-#{(@d2.month+1)}-1",
        "_self"
      )
    else
      $("#magnitude-search").html("<p>Calculated magnitude cutoff : </p><p style='color:green'>\
        #{@_binarySearch(0, 100)}</p>")

  _binarySearch: (mag, max) ->
    if  mag < max
      count = 0
      count = @magArray[mag][d2.year * 12 + d2.month] - @magArray[mag][d1.year * 12 + d1.month]
      if count > 20000
        nextMag = mag + (max - mag) / 2
        return binarySearch(nextMag, max)
      else if count < 15000 and mag isnt 0
        nextMag = mag - (max - mag) / 2
        return binarySearch(nextMag, mag)
      else
        return mag / 10
    else
      return max / 10

module.exports = new MagnitudeSearch()
