$(document).ready ->
  $('.song-name').click (event) ->
    $songCard = $(event.target).closest('.song-card')
    source = $songCard.data('media_source')
    id = $songCard.data('media_id')
    debugger

