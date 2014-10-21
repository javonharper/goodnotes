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
  RELATED_ARTIST_POOL = 10
  RELATED_ARTIST_SELECT = 3

end

def find_artist(query)
  results = settings.lastfm.artist.search({artist: query.strip, limit: 5})
  matches = results['results']['artistmatches']

  if matches.empty?
    nil
  else
    artists = [matches['artist']].flatten

    exact_match = artists.find do |artist|
      artist['name'].downcase == query.downcase
    end

    artist = exact_match || artists.first
    OpenStruct.new(artist)
  end
end

def find_similar_artists(query, pool=RELATED_ARTIST_POOL, select=RELATED_ARTIST_SELECT)
  results = settings.lastfm.artist.get_similar(artist: query.strip, limit: pool)    

  # Remove first element, since it is just the query.
  results.shift

  selection_pool = results.first(pool).map do |r|
    {
      name: r['name'],
      image: r['image'].last['content']
    }
  end

  selection_pool.shuffle.first(select)
end

def find_info(query)
  results = settings.lastfm.artist.get_info(artist:query.strip)
  results["bio"]["summary"]
end

get '/' do
  @page_title = "Goodnot.es - Discover the best tracks of any artist or band"
  haml :index, locals: {
    show_search_more_button: false
  }
end

get '/search' do
  query = params['query'].strip

  if query.empty?
    raise Sinatra::NotFound
  end

  artist = find_artist(query)

  if artist.nil? or artist.marshal_dump.empty?
    raise Sinatra::NotFound
  else
    redirect to("listen/#{CGI::escape(artist.name)}")
  end
end

get '/listen/:artist' do |artist|
  num_songs = params['songs']? params['songs'].to_i : NUM_SONGS 

  begin
    artist_name = CGI::unescape(artist)
    t1 = Thread.new {
      Thread.current[:artist] = find_artist(artist_name)
    }

    t2 = Thread.new {
      Thread.current[:tracks] = settings.lastfm.artist.get_top_tracks({artist: artist_name, limit: num_songs})
    }

    t3 = Thread.new {
      Thread.current[:similar] = find_similar_artists(artist_name)
    }

    t4 = Thread.new {
      Thread.current[:info] = find_info(artist_name)
    }

    [t1, t2, t3, t4].each {|t| t.join}
  rescue StandardError => execption
    raise Sinatra::NotFound
  end

  artist = t1[:artist]
  top_tracks = t2[:tracks].first(num_songs)
  similar_artists = t3[:similar].map {|artist| {
    name: artist[:name], 
    escaped_name: CGI::escape(artist[:name]),
    image_url: artist[:image]
  }}
  info = t4[:info]

  @page_title = "Listen to #{artist.name}'s best songs - Goodnot.es"
  @page_description = 
    "
      Listen to the 5 most popular songs by #{artist.name}:
      #{ top_tracks.first(NUM_SONGS).map {|s| s['name']}.join(', ') }
    "

  media_threads = []
  top_tracks.each.with_index do |song, i|
    media_threads << Thread.new do
      song = OpenStruct.new(song)
      media_result = OpenStruct.new(YoutubeSearch.search("#{artist.name} #{song.name}", per_page: 1).first)
      Thread.current[:song] = {
        number: i + 1,
        artist: artist.name,
        name: song.name,
        media_source: 'youtube',
        media_id: media_result.video_id,
        media_url: "https://www.youtube.com/watch?v=#{media_result.video_id}"
      }
    end
  end

  media_threads.each{ |t| t.join }
  songs = media_threads.map {|t| t[:song]}

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

get '/application.js' do
  content_type "text/javascript"
  compiled =  coffee :application

  if settings.development?
    compiled
  else
    Uglifier.compile(compiled)
  end
end

get '/stylesheets/application.css' do
  sass(:custom_bootstrap) << sass(:application)
end

not_found do
  @page_title = 'Goodnot.es - Artist/Band could not be found.'
  haml :notfound, locals: {
    show_search_more_button: true
  }
end
