# config.ru (run with rackup)
require 'isolated_database_service'
run IsolatedDatabaseService::Application
