// @format

var express = require('express')
var router = express.Router()
var Lastfm = require('lastfmapi')
var Youtube = require('youtube-api')
var Q = require('q')
var _ = require('underscore')
var config = require('config')

var lastfm = new Lastfm({
  api_key: config.lastfm.apiKey,
  secret: config.lastfm.secret,
})

Youtube.authenticate({
  type: 'key',
  key: config.youtube.key,
})

router.get('/:artist', function(req, res, next) {
  var artist = decodeString(req.params.artist)

  Q.all([getInfo(artist), getTopTracks(artist)]).then(
    function(response) {
      var info = response[0]
      var topTracks = response[1]

      Q.all(
        topTracks.map(function(track) {
          return getTrackVideo(artist, track.name)
        }),
      ).then(
        function(videoResponse) {
          res.render('listen', {
            title: info.name + "'s most popular songs - Goodnotes.io",
            artist: info.name,
            summary: info.summary,
            emptySummary: info.summary.indexOf('<') === 1,
            imageUrl: info.image,
            tags: info.tags,
            tracks: videoResponse,
            similarArtists: info.similarArtists,
          })
        },
        function(errs) {
          return next(errs)
        },
      )
    },
    function(errs) {
      return next(errs)
    },
  )
})

var getTopTracks = function(artist) {
  var deferred = Q.defer()

  lastfm.artist.getTopTracks(
    { artist: artist, autocorrect: 1, limit: 5 },
    function(err, res) {
      if (err) {
        deferred.reject()
      } else {
        deferred.resolve(
          res.track.map(function(track) {
            return { name: track.name }
          }),
        )
      }
    },
  )

  return deferred.promise
}

var getInfo = function(artist) {
  var deferred = Q.defer()

  lastfm.artist.getInfo({ artist: artist, autocorrect: 1 }, function(
    err,
    info,
  ) {
    if (err) {
      deferred.reject(err)
    } else {
      deferred.resolve({
        name: info.name,
        summary: info.bio.summary,
        image: info.image[4]['#text'],
        similarArtists: _.first(_.shuffle(info.similar.artist), 3).map(function(
          artist,
        ) {
          return {
            name: artist.name,
            imageUrl: artist.image[4]['#text'],
            goodnotesUrl: '/listen/' + encodeString(artist.name),
          }
        }),
        tags: _.first(info.tags.tag, 3).map(function(tag) {
          return tag.name
        }),
      })
    }
  })

  return deferred.promise
}

var getTrackVideo = function(artist, track) {
  var deferred = Q.defer()

  Youtube.search.list(
    {
      q: artist + ' ' + track,
      part: 'id',
      maxResults: 1,
    },
    function(err, result) {
      if (_.isEmpty(_.first(result.items))) {
        err = new Error('Cound not find video for ' + artist + ' - ' + track)
      }

      if (err) {
        deferred.reject()
      } else {
        var videoId = _.first(result.items).id.videoId

        deferred.resolve({
          artist: artist,
          name: track,
          videoId: videoId,
        })
      }
    },
  )

  return deferred.promise
}

function encodeString(str) {
  return encodeURIComponent(str).replace(/%20/g, '-')
}

function decodeString(str) {
  return decodeURIComponent(str.replace(/-/g, '%20'))
}

module.exports = router
