# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'isolated_service/version'

Gem::Specification.new do |gem|
  gem.name          = "isolated_service"
  gem.version       = IsolatedService::VERSION
  gem.authors       = ["Gary Grossman"]
  gem.email         = ["gary.grossman@gmail.com"]
  gem.summary       = %q{Service wrapper for the isolated_server gem.}
  gem.description   = %q{A small service that allows you to easily spin up new local mysql/mongo servers for testing purposes.}
  gem.homepage      = "http://github.com/ggrossman/isolated_service"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rspec"
end
