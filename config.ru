# config.ru (run with rackup)
require 'rack/parser'
require 'isolated_service'
require 'json'

use Rack::Parser, :parsers => { 'application/json' => Proc.new { |data| JSON.parse data } }

run IsolatedService
