var express = require('express');
var router = express.Router();

var Lastfm = require('lastfmapi');
var Youtube = require('youtube-api');
var Q = require('q');
var _ = require('underscore');

var lastfm = new Lastfm({
  'api_key' : '5a1964f7a064939dbc6a5fce2570f3f1',
  'secret' : '6159650243f21ae79d0fd1f2e9f7f886'
});

Youtube.authenticate({
  type: 'key',
  key: 'AIzaSyCbw0MmNUhgTmRczQOjX-w0wdxWD_eCxz8'
});

router.get('/:artist', function(req, res, next) {
  var artist = req.params.artist;

  Q.all([
    getInfo(artist),
    getTopTracks(artist)
  ]).then(function(response) {

    var info = response[0];
    var topTracks = response[1];

    Q.all(topTracks.map(function(track) {
      return getTrackVideo(artist, track.name);
    })).then(function(videoResponse) {
      res.render('listen', {
        title: artist + "'s most popular songs - Goodnotes.io",
        artist: artist, 
        summary: info.summary,
        emptySummary: info.summary.indexOf("<") === 1,
        imageUrl: info.image,
        tags: info.tags,
        tracks: videoResponse,
        similarArtists: info.similarArtists
      });
    });
  });
});

var getTopTracks = function(artist) {
  var deferred = Q.defer();

  lastfm.artist.getTopTracks({artist: artist, limit: 5}, function(err, topTracks) {
    if (err) {
      deferred.reject();
    }

    deferred.resolve(topTracks.track.map(function(track) { 
      return { name: track.name };
    }));
  });

  return deferred.promise;
};

var getInfo = function(artist) {
  var deferred = Q.defer();

  lastfm.artist.getInfo({artist: artist}, function(err, info) {
    if (err) {
      deferred.reject(err);
    }

    deferred.resolve({
      summary: info.bio.summary,
      image: info.image[4]['#text'],
      similarArtists: _.first(_.shuffle(info.similar.artist), 3).map(function(artist) {
        return {
          name: artist.name,
          imageUrl: artist.image[4]['#text'],
          goodnotesUrl: "/listen/" + artist.name

        }
      }),
      tags: _.first(info.tags.tag, 3).map(function(tag){ 
        return tag.name 
      })
    });
  });

  return deferred.promise;
};

var getTrackVideo = function(artist, track) {
  var deferred = Q.defer();

  Youtube.search.list({
    q: artist + ' ' + track,
    part: 'id',
    maxResults: 1
  }, function(err, result) {
    if (err) {
      deferred.reject();
    }

    var videoId = _.first(result.items).id.videoId;

    deferred.resolve({
      artist: artist,
      name: track,
      videoId: videoId
    });
  });

  return deferred.promise;
}

module.exports = router;
