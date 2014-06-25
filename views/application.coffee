App = window.App = window.App || {}

ENDED = 0

window.onYouTubePlayerReady = ->
  App.player = document.getElementById('myytplayer')
  App.player.addEventListener('onStateChange', 'onStateChange')

window.onStateChange = (state) ->
  if state is ENDED
    App.playNextSong()

App.playNextSong = ->
  index = _.indexOf(App.songs, App.currentSong) + 1

  if App.songs[index]
    App.currentSong = App.songs[index]
    App.playSong(App.currentSong)

App.playPrevSong = ->
  index = _.indexOf(App.songs, App.currentSong) - 1

  if App.songs[index]
    App.currentSong = App.songs[index]
    App.playSong(App.currentSong)

App.playSong = (song) ->
  $('.current-song-name').text(App.currentSong['name'])
  App.player.loadVideoById(App.currentSong['media_id'])

$(document).ready ->
  $('.song-name').click (event) ->
    $songCard = $(event.target).closest('.song-card')
    source = $songCard.data().mediaSource
    id = $songCard.data().mediaId

    App.currentSong = _.findWhere(App.songs, media_id: id)
    App.playSong(App.currentSong)

  $('.search-form button').click (event) ->
    $(event.target).find('.search-label').text('Searching...')
    $icon = $('.search-icon')
    $icon.removeClass('fa-play')
    $icon.addClass('fa-spinner')
    $icon.addClass('fa-spin')

  $('.prev-song').click(App.playPrevSong)
  $('.next-song').click(App.playNextSong)

