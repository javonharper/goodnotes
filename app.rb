require 'bootstrap-sass'
require 'cgi'
require 'coffee-script'
require 'compass'
require 'haml'
require 'lastfm'
require "open-uri"
require 'ostruct'
require 'pry'
require 'sass'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'sinatra/reloader' if development?
require 'tempfile'
require 'uglifier'
require 'youtube_search'

configure do
  ### Server Configuration
  config_file 'config.yml' 

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

  set :lastfm, Lastfm.new(api_key, api_secret)

  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir = 'views/stylesheets/'
  end

  ### Application Configuration
  NUM_SONGS = 5

end

class API
  def initialize(lastfm_client)
    @lastfm = lastfm_client
  end

  def find_artist(query)
    results = @lastfm.artist.search({artist: query.strip})
    matches = results['results']['artistmatches']

    if matches.empty?
      nil
    else
      artists = [matches['artist']].flatten

      exact_match = artists.find do |artist|
        artist['name'].downcase == query.downcase
      end

      artist = exact_match or artists.first
      OpenStruct.new(artist)
    end
  end
end

api = API.new(settings.lastfm)

get '/' do
  @page_title = "Goodnot.es - Discover the best tracks of any artist or band"
  haml :index
end

get '/search' do
  query = params['query']

  if query.empty?
    redirect to('/notfound')
  end

  artist = api.find_artist(query)

  if artist.nil? or artist.marshal_dump.empty?
    redirect to('/notfound')
  else
    redirect to("listen/#{CGI::escape(artist.name)}")
  end
end

get '/listen/:artist' do |artist|
  artist_name = CGI::unescape(artist)
  artist = api.find_artist(artist_name)
  @page_title = "#{artist.name}'s best songs - Goodnot.es"

  begin
    top_tracks = settings.lastfm.artist.get_top_tracks({artist: artist.name})
  rescue StandardError => e
    redirect to('/notfound')
  end

  songs = top_tracks.first(NUM_SONGS).map  do |song|
    song = OpenStruct.new(song)
    media_result = OpenStruct.new(YoutubeSearch.search("#{artist.name} #{song.name}").first)
    song = {
      artist: artist.name,
      name: song.name,
      media_source: 'youtube',
      media_id: media_result.video_id,
      media_url: "https://www.youtube.com/watch?v=#{media_result.video_id}",
    }
  end

  template = if artist.name.downcase == 'creed'
    :creed
  else
    :listen
  end

  haml template, locals: {
    songs: songs,
    share_url: request.url,
    artist: artist.name,
    artist_image_url: artist.image.last['content']
  }
end

get '/notfound' do
  @page_title = 'Goodnot.es - Artist/Band could not be found.'
  haml :notfound
end

### Scripts
get '/application.js' do
  content_type "text/javascript"
  compiled =  coffee :application

  if settings.development?
    compiled
  else
    Uglifier.compile(compiled)
  end
end

### Stylesheets

get '/stylesheets/application.css' do
  sass(:custom_bootstrap) << sass(:application)
end
