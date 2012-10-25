# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'protobuf/activerecord/version'

Gem::Specification.new do |gem|
  gem.name          = "protobuf-activerecord"
  gem.version       = Protobuf::ActiveRecord::VERSION
  gem.authors       = ["Adam Hutchison"]
  gem.email         = ["adam@moneydesktop.com"]
  gem.homepage      = "http://git.moneydesktop.com/adam-hutchison/protobuf-activerecord"
  gem.summary       = %q{Google Protocol Buffers integration for Active Record}
  gem.description   = %q{Provides the ability to create Active Record objects from Protocol Buffer messages and vice versa.}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  ##
  # Dependencies
  #
  gem.add_dependency "activerecord"
  gem.add_dependency "protobuf", ">= 2.0"

  ##
  # Development dependencies
  #
  gem.add_development_dependency "rake"
  gem.add_development_dependency "geminabox"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rspec-pride"
  gem.add_development_dependency "pry-nav"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "sqlite3"
end
