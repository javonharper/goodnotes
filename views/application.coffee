App = window.App = window.App || {}

VIDEO_ENDED = 0

window.onYouTubePlayerReady = ->
  App.player = document.getElementById('myytplayer')
  App.player.addEventListener('onStateChange', 'onStateChange')

window.onStateChange = (state) ->
  if state is VIDEO_ENDED
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
  App.currentSong = _.first(App.songs)

  if App.currentSong
    params =  allowScriptAccess: "always"
    atts = id: "myytplayer"

    artist = App.songs[0].artist


    # !!! EASTER EGG !!!
    # Play 'Shreds' video if they match one of the artists below

    ytId = switch artist
      when 'Creed' then 'bVswiiI_PmU'
      when 'Kings of Leon' then 'NOF1FJ7wGhw'
      when 'Kiss' then 'Kw5oJoUYTb8'
      when 'Korn' then 'fZOXC_t6dk8'
      when 'Nickleback' then 'FuGW4_V0sbQ'
      when 'Yo-Yo Ma' then 'ka-sHA74N40'
      when 'Metallica' then 'nDUHB_RbtzY'
      when 'Red Hot Chili Peppers' then 'jdmIiE_LM_I'
      else App.songs[0]['media_id']

    swfobject.embedSWF "http://www.youtube.com/v/#{ytId}?enablejsapi=1&playerapiid=ytplayer&version=3&autoplay=1&color=white&fs=0&modestbranding=1&rel=0",
                       "ytapiplayer", "425", "356", "8", null, null, params, atts

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

