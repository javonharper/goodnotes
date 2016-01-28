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
    };

    function onPlayClicked(event) {
      var videoId = $(event.target).closest('.play-track').data().videoId;
      currentTrack = _.findWhere(tracks, {videoId: videoId});
      playTrack(currentTrack);
    };

    function playNextTrack() {
      var index = _.indexOf(tracks, currentTrack) + 1;
      if (tracks[index]) {
        currentTrack = tracks[index];
        playTrack(currentTrack);
      }
    };

    function playPrevTrack() {
      var index = _.indexOf(tracks, currentTrack) - 1;
      if (tracks[index]) {
        currentTrack = tracks[index];
        playTrack(currentTrack);
      }
    };

    function playTrack(track) {
      Player.__player__.loadVideoById(track.videoId);
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
