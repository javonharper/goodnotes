App = window.App = window.App || {}

window.onPlayerReady = (event) ->
  event.target.playVideo()

window.onPlayerStateChange = (event) ->
  if event.data == YT.PlayerState.ENDED
    index = _.indexOf(App.songs, App.currentSong) + 1

    if _.isEmpty(App.songs[index])
      App.playNextArtist()
    else
      App.playNextSong()

window.onYouTubeIframeAPIReady = ->
  song = _.first(App.songs)

  if song
    App.player = new YT.Player 'player',
      height: '400',
      width: '100%',
      videoId: song['media_id'],
      events:
        onReady: window.onPlayerReady,
        onStateChange: window.onPlayerStateChange

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
  $('.current-song-name').text(song['name'])
  App.player.loadVideoById(song['media_id'])

App.playNextArtist = () ->
  artist = _.first(App.similarArtists)
  window.location.href = "/listen/#{artist.escaped_name}"

indicateSearching = ->
  $('.search-label').text('Searching...')
  $icon = $('.search-icon')
  $icon.removeClass('fa-play')
  $icon.addClass('fa-spinner')
  $icon.addClass('fa-spin')

initTypeahead = ->
  artists = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: '/autocomplete/%QUERY'
  })
   
  artists.initialize()
   
  $('.typeahead').typeahead(null, {
    name: 'artists',
    displayKey: 'value',
    source: artists.ttAdapter(),
    templates: {
      # empty: [
      #   '<div class="empty-message">',
      #     'unable to find any Best Picture winners that match the current query',
      #   '</div>'
      # ].join('\n'),
      suggestion: Handlebars.compile(
        '<div class="autocomplete-suggestion">
          <strong>
            {{value}}
          </strong>
        </div>'
      )
    }
  })

  $('.typeahead').on 'typeahead:selected', (event, suggestion, dataset) =>
    indicateSearching()
    $('form').submit()

initPopovers = ->
  $('.info').popover
    placement: 'bottom'
    html: true

$(document).ready ->
  initTypeahead()
  initPopovers()
  App.currentSong = _.first(App.songs)

  if App.currentSong
    artist = App.songs[0].artist

    # !!! EASTER EGG !!!
    # Play 'Shreds' video if they match one of the artists below

    ytId = switch artist
      when 'Creed' then 'bVswiiI_PmU'
      when 'Kings of Leon' then 'NOF1FJ7wGhw'
      when 'Kiss' then 'Kw5oJoUYTb8'
      when 'Korn' then 'fZOXC_t6dk8'
      when 'Nickelback' then 'FuGW4_V0sbQ'
      when 'Yo-Yo Ma' then 'ka-sHA74N40'
      when 'Metallica' then 'nDUHB_RbtzY'
      when 'Red Hot Chili Peppers' then 'jdmIiE_LM_I'
      else App.songs[0]['media_id']

  $('.song-name').click (event) ->
    $songCard = $(event.target).closest('.song-card')
    source = $songCard.data().mediaSource
    id = $songCard.data().mediaId

    App.currentSong = _.findWhere(App.songs, media_id: id)
    App.playSong(App.currentSong)

  $('.search-form button').click indicateSearching
  $('.prev-song').click(App.playPrevSong)
  $('.next-song').click(App.playNextSong)
