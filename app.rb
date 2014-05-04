require 'sinatra'
require 'haml'
require 'compass'
require 'sass'
require 'pry'
require 'bootstrap-sass'
require 'coffee-script'

configure do
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir = 'views/stylesheets/'
  end
end

set :haml, format: :html5
set :sass, Compass.sass_engine_options

get '/' do
  haml :index
end

get '/application.js' do
  content_type "text/javascript"
  coffee :application
end

get '/stylesheets/application.css' do
  sass :application
end
