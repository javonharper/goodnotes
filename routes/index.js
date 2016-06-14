var express = require('express');
var router = express.Router();
var Lastfm = require('lastfmapi');

var lastfm = new Lastfm({
  'api_key' : '5a1964f7a064939dbc6a5fce2570f3f1',
  'secret' : '6159650243f21ae79d0fd1f2e9f7f886'
});

router.get('/', function(req, res, next) {
  res.render('index', { 
    title: 'Listen to the best tracks of any artist - Goodnotes.io'
  });
});

router.get('/search', function(req, res, next) {
  var query = req.query.query;

  lastfm.artist.search({artist: query, limit: 5}, function(err, artist) {
    if (err) {
      next(err);
    } else {
      var artist = artist.artistmatches.artist[0].name;
      res.redirect('/listen/' + encodeString(artist));
    }
  });
});

router.get('/autocomplete/:query', function(req, res, next) {
  lastfm.artist.search({artist: req.params.query, limit: 3}, function(err, artistResults) {
    if (err) {
        console.log("Error: Could not find autocomplete for query: " + req.params.query);
    }

    res.send(artistResults.artistmatches.artist.map(function(artist) { 
      return {value: artist.name} 
    }));
  });
});

function encodeString(str) {
  return encodeURIComponent(str).replace(/%20/g, "-");
};

function decodeString(str) {
  return decodeURIComponent(str.replace(/-/g, "%20"));
};

module.exports = router;
