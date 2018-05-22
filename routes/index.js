// @format

var express = require('express')
var router = express.Router()
var Lastfm = require('lastfmapi')
var config = require('config')

var lastfm = new Lastfm({
  api_key: config.lastfm.apiKey,
  secret: config.lastfm.secret,
})

router.get('/', function(req, res, next) {
  res.render('index', {
    title: 'Listen to the best songs of any artist - Goodnotes.io',
  })
})

router.get('/search', function(req, res, next) {
  var query = req.query.query

  lastfm.artist.search({ artist: query, limit: 5 }, function(err, artist) {
    if (err) {
      next(err)
    } else {
      var artist = artist.artistmatches.artist[0].name
      res.redirect('/listen/' + encodeString(artist))
    }
  })
})

router.get('/autocomplete/:query', function(req, res, next) {
  lastfm.artist.search({ artist: req.params.query, limit: 3 }, function(
    err,
    artistResults,
  ) {
    if (err) {
      console.log(
        'Error: Could not find autocomplete for query: ' + req.params.query,
      )
    }

    res.send(
      artistResults.artistmatches.artist.map(function(artist) {
        return { value: artist.name }
      }),
    )
  })
})

function encodeString(str) {
  return encodeURIComponent(str).replace(/%20/g, '-')
}

function decodeString(str) {
  return decodeURIComponent(str.replace(/-/g, '%20'))
}

module.exports = router
