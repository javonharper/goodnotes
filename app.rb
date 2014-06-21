require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'haml'
require 'compass'
require 'sass'
require 'bootstrap-sass'
require 'coffee-script'
require 'lastfm'
require 'pry'
require 'cgi'
require 'youtube_search'

require 'sinatra/reloader' if development?

### Server Configuration
config_file 'config.yml' 

configure do
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir = 'views/stylesheets/'
  end
end

set :haml, format: :html5
set :sass, Compass.sass_engine_options

### Library Configuration
begin
  api_key = settings.LASTFM_API_KEY 
  api_secret = settings.LASTFM_SECRET_KEY
rescue
  api_key = ENV['LASTFM_API_KEY']
  api_secret = ENV['LASTFM_SECRET_KEY']
end

lastfm = Lastfm.new(api_key, api_secret)

### Application Configuration
NUM_SONGS = 5

get '/' do
  @page_title = "Goodnot.es - Discover the best tracks of any artist or band"
  haml :index
end

get '/search' do
  query = params['query']
  results = lastfm.artist.search({artist: query})

  matches = results['results']['artistmatches']
  if matches.empty?
    redirect to('/notfound')
  else
    artist = matches['artist'].first['name']
    redirect to("listen/#{CGI::escape(artist)}")
  end
end

get '/listen/:artist' do |artist|
  artist = CGI::unescape(artist)

  @page_title = "Goodnot.es - Listen to #{artist}'s best tracks"

  artist_results = lastfm.artist.search({artist: artist})

  top_tracks = lastfm.artist.get_top_tracks({artist: artist})
  songs = top_tracks.first(NUM_SONGS).map  do |song|
    media_result = YoutubeSearch.search("#{artist} #{song['name']}").first
    song = {
      artist: song['artist']['name'],
      name: song['name'],
      media_source: 'youtube',
      youtube_media_id: media_result['video_id'],
      youtube_media_url: "https://www.youtube.com/watch?v=#{media_result['video_id']}",
    }

    song
  end

  haml :listen, locals: {
    songs: songs,
    artist: artist_results['results']['artistmatches']['artist'].first['name'],
    artist_image_url: artist_results['results']['artistmatches']['artist'].first['image'].last['content']
  }
end

get '/notfound' do
  @page_title = 'Goodnot.es - Artist/Band could not be found.'
  haml :notfound
end

### Scripts
get '/application.js' do
  content_type "text/javascript"
  coffee :application
end

get '/stylesheets/application.css' do
  sass(:custom_bootstrap) << sass(:application)
end
