var Goodnotes = Goodnotes || {};
Goodnotes.Player = Goodnotes.Player || {};

(function() {
  $(function() {
    var Player = Goodnotes.Player;
    var tracks = Goodnotes.Player.tracks;
    var currentTrack = null;

    currentTrack = _.first(tracks);

    $('.play-prev-track').on('click', playPrevTrack);
    $('.play-next-track').on('click', playNextTrack);
    $('.play-track').on('click', onPlayClicked);

    window.onYouTubeIframeAPIReady = function() {
      var track = _.first(tracks);

      Player.__player__ = new YT.Player('player', 
        {
          height: "400",
          width: "100%",
          videoId: track.videoId,
          events: {
            onReady: onPlayerReady,
            onStateChange: onPlayerStateChange
          }
      });

      currentTrack = track;
      $('.track-list-item').first().addClass('active');
      playTrack(track);
    };

    function onPlayClicked(event) {
      $('.track-list-item.active').removeClass('active');
      $(event.target).closest('.track-list-item').addClass('active');

      var videoId = $(event.target).closest('.play-track').data().videoId;
      playTrack(_.findWhere(tracks, {videoId: videoId}));
    };

    function playNextTrack() {
      var index = _.indexOf(tracks, currentTrack) + 1;
      if (tracks[index]) {
        playTrack(tracks[index]);
      }
    };

    function playPrevTrack() {
      var index = _.indexOf(tracks, currentTrack) - 1;
      if (tracks[index]) {
        playTrack(tracks[index]);
      }
    };

    function playTrack(track) {
      $('.track-status').addClass('ion-play');
      $('.track-status').removeClass('ion-volume-high');
      $('*[data-video-id='+ track.videoId+']').find('.track-status').addClass('ion-volume-high');

      if (track !== currentTrack) {
        Player.__player__.loadVideoById(track.videoId);
        currentTrack = track;
      }
    };

    function onPlayerReady(event) {
      event.target.playVideo();
    };

    function onPlayerStateChange(event) {
      if (event.data === YT.PlayerState.ENDED) {
        var index = _.indexOf(tracks, currentTrack) + 1;
        if (!_.isEmpty(tracks[index])) {
          playNextTrack();
        }
      }
    };
  });
})();
