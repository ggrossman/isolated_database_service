# config.ru (run with rackup)
require 'rack/parser'
require 'isolated_database_service'
require 'json'

use Rack::Parser, :parsers => { 'application/json' => Proc.new { |data| JSON.parse data } }

run IsolatedDatabaseService::Application
