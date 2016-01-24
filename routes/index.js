var express = require('express');
var router = express.Router();
var LastfmAPI = require('lastfmapi');
var Q = require('q');

var lastfm = new LastfmAPI({
  'api_key' : '5a1964f7a064939dbc6a5fce2570f3f1',
  'secret' : '6159650243f21ae79d0fd1f2e9f7f886'
});

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Goodnotes' });
});

router.get('/search', function(req, res, next) {
  var query = req.query.query;

  lastfm.artist.search({artist: query, limit: 5}, function(err, artist) {
    if (err) {
      handleError
    }

    var artist = artist.artistmatches.artist[0].name
    res.redirect('/listen/' + artist)
  });
});

router.get('/listen/:artist', function(req, res, next) {
  var artist = req.params.artist;

  Q.all([
    getInfo(artist),
    getTopTracks(artist)
  ]).then(function(response) {

    var info = response[0];
    var topTracks = response[1];

    res.render('listen', {
      title: artist + "'s most popular songs - Goodnotes.io",
      artist: artist, 
      summary: info.summary,
      imageUrl: info.image,
      tags: info.tags,
      tracks: topTracks,
      similar_artists: info.similar_artists
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
      deferred.reject();
    }

    deferred.resolve({
      summary: info.bio.summary,
      image: info.image[4]['#text'],
      similar_artists: info.similar.artist.map(function(artist) {
        return {
          name: artist.name,
          image: artist.image[4]['#text']
        }
      }),
      tags: info.tags.tag.map(function(tag){ 
        return tag.name 
      })
    });
  });

  return deferred.promise;
};

module.exports = router;
