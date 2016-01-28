var express = require('express');
var router = express.Router();
var Lastfm = require('lastfmapi');

var lastfm = new Lastfm({
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


module.exports = router;
