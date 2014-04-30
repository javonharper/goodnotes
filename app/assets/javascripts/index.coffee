$ ->
  console.dir jsRoutes
  $('#submit-artist').click ->
    artistName = $('#artist-name').val()
    $.ajax(
      type: 'POST'
      url: '/api/search'
      data:
        query: artistName
    ).done((data) ->
      debugger
    )
