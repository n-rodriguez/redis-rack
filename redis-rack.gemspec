# frozen_string_literal: true

require_relative 'lib/redis/rack/version'

Gem::Specification.new do |s|
  s.name        = 'redis-rack'
  s.version     = Redis::Rack::VERSION
  s.authors     = ['Luca Guidi']
  s.email       = ['me@lucaguidi.com']
  s.homepage    = 'http://redis-store.org/redis-rack'
  s.summary     = 'Redis Store for Rack'
  s.description = 'Redis Store for Rack applications'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.7.0'

  s.files = Dir['README.md', 'MIT-LICENSE', 'CHANGELOG.md', 'lib/**/*.rb']

  s.add_dependency 'rack-session',  '>= 0.2.0'
  s.add_dependency 'redis-store',   ['< 2', '>= 1.2']
end
