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
require 'youtube_g'

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
api_key = settings.LASTFM_API_KEY 
api_secret = settings.LASTFM_SECRET_KEY

lastfm = Lastfm.new(api_key, api_secret)

youtube = YoutubeG::Client.new

### Application Configuration
NUM_SONGS = 5

get '/' do
  haml :index
end

get '/search' do
  query = params['query']
  results = lastfm.artist.search({artist: query})
  matches = results['results']['artistmatches']['artist']
  unless matches.empty?
    artist = matches.first['name']
    redirect to("listen/#{CGI::escape(artist)}")
  end
end

get '/listen/:artist' do |artist|
  artist = CGI::unescape(artist)
  results = lastfm.artist.get_top_tracks({artist: artist})
  songs = results.first(NUM_SONGS).map  do |song|
    song = {}
    youttube.videos_by(query: "#{song} #{artist}")
  end

  haml :listen, locals: {
    songs: songs
  }
end

get '/application.js' do
  content_type "text/javascript"
  coffee :application
end

get '/stylesheets/bootstrap.css' do
  sass :custom_bootstrap
end
get '/stylesheets/application.css' do
  sass :application
end
