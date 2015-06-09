require 'coffee-script'
require 'celluloid'
require 'lastfm'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/config_file'
require 'google/api_client'
 
require 'sinatra/reloader' if development?
require 'pry' if development?

require_relative 'async'

class App < Sinatra::Base
  register Sinatra::ConfigFile

  configure :development do
    register Sinatra::Reloader
    also_reload 'async.rb'
  end

  configure do
    config_file 'config/config.yml' 

    begin
      api_key = settings.LASTFM_API_KEY 
      api_secret = settings.LASTFM_SECRET_KEY
      youtube_key = settings.YOUTUBE_API_KEY
    rescue
      api_key = ENV['LASTFM_API_KEY']
      api_secret = ENV['LASTFM_SECRET_KEY']
      youtube_key = ENV['YOUTUBE_API_KEY']
    end

    set :lastfm, Lastfm.new(api_key, api_secret)
    set :google_client, Google::APIClient.new(
      key: youtube_key, 
      application_name: 'Goodnotes.io')
    set :youtube, settings.google_client.discovered_api('youtube', 'v3')

    NUM_SONGS = 5
    RELATED_ARTIST_POOL = 10
    RELATED_ARTIST_SELECT = 3
    ARTISTS_PER_CATEGORY = 5
  end

  get '/' do

    # popular = OpenStruct.new(title: 'Popular', source: 'music')
    # recommended = OpenStruct.new(title: 'Recommended', source: 'listentothis')
    # obscure = OpenStruct.new(title: 'Obscure', source: 'listentoobscure')

    # category_artists = [popular, recommended, obscure].map do |category|
    #   result = RestClient.get "https://goodnotes-reddit-api.herokuapp.com/r/#{category.source}.json"
    #   top_artists = JSON.parse(result).shuffle.first(ARTISTS_PER_CATEGORY)
    #   OpenStruct.new(title: category.title, artists: top_artists)
    # end

    @page_title = "Goodnotes.io - Discover the best tracks of any artist or band"
    haml :index, locals: {
      show_search_more_button: false,
      # popular: category_artists[0],
      # recommended: category_artists[1],
      # obscure: category_artists[2]
    }
  end

  get '/listen/:artist' do |artist_name|
    artist_name = CGI::unescape(artist_name)
    num_songs = params['songs']? params['songs'].to_i : NUM_SONGS 

    artist_future = Async::ArtistFinder.new(settings.lastfm, artist_name).future.run
    tracks_future = Async::TopTracksFinder.new(settings.lastfm, artist_name, num_songs).future.run
    artist_info_future = Async::ArtistInfoFinder.new(settings.lastfm, artist_name).future.run
    similar_artists_future = Async::SimilarArtistsFinder.new(settings.lastfm, artist_name, RELATED_ARTIST_POOL, RELATED_ARTIST_SELECT).future.run

    artist = artist_future.value
    top_tracks = tracks_future.value
    info = artist_info_future.value 
    similar_artists = similar_artists_future.value

    song_futures = top_tracks.map.with_index do |track, i|
      Async::SongFinder.new(settings.google_client, settings.youtube, artist.name, track['name'], i).future.run
    end

    songs = song_futures.map(&:value)

    @page_title = "#{artist.name}'s most popular songs - Goodnotes.io"
    @page_description = 
      "
        Listen to the 5 most popular songs by #{artist.name}:
        #{top_tracks.first(NUM_SONGS).map {|s| s['name']}.join(', ')}
      "
    haml :listen, locals: {
      songs: songs,
      share_url: request.url,
      artist: artist.name,
      artist_image_url: artist.image.last['content'],
      info: info,
      similar_artists: similar_artists,
      show_search_more_button: true
    }
  end

  get '/autocomplete/:query' do |query|
    results = settings.lastfm.artist.search({artist: query.strip, limit: 5})
    artists = results['results']['artistmatches']['artist']

    autocomplete_results = artists.map do |artist|
      {
        value: artist['name']
      }
    end

    json autocomplete_results
  end

  get '/search' do
    query = params['query'].strip

    if query.empty?
      raise Sinatra::NotFound
    end

    artist = Async::ArtistFinder.new(settings.lastfm, query).run

    if artist.nil? or artist.marshal_dump.empty?
      raise Sinatra::NotFound
    else
      redirect to("listen/#{CGI::escape(artist.name)}")
    end
  end

  get '/application.js' do
    coffee :application
  end

  get '/stylesheets/application.css' do
    sass :application
  end

  not_found do
    @page_title = 'Goodnotes.io - Artist/Band could not be found.'
    haml :notfound, locals: {
      show_search_more_button: true
    }
  end
end

# require 'bootstrap-sass'
# require 'uglifier'
# require 'cgi'
# require 'compass'
# require 'haml'
# require "open-uri"
# require 'ostruct'
# require 'sass'
# require 'sinatra/assetpack'
# require 'rest-client'
# require 'tempfile'
