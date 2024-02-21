# -*- encoding: utf-8 -*-

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "protobuf/active_record/version"

Gem::Specification.new do |spec|
  spec.name          = "protobuf-activerecord"
  spec.version       = Protobuf::ActiveRecord::VERSION
  spec.authors       = ["Adam Hutchison"]
  spec.email         = ["liveh2o@gmail.com"]
  spec.homepage      = "http://github.com/liveh2o/protobuf-activerecord"
  spec.summary       = "Google Protocol Buffers integration for Active Record"
  spec.description   = "Provides the ability to create Active Record objects from Protocol Buffer messages and vice versa."
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  ##
  # Dependencies
  #
  spec.add_dependency "activerecord", "~> 7.0.0"
  spec.add_dependency "activesupport", "~> 7.0.0"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "heredity", ">= 0.1.1"
  spec.add_dependency "protobuf", ">= 3.0"

  ##
  # Development dependencies
  #
  spec.add_development_dependency "benchmark-ips"
  spec.add_development_dependency "mad_rubocop"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.3.0"
  spec.add_development_dependency "rspec-pride", ">= 3.1.0"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "simplecov"

  if ENV["PLATFORM"] == "java" || ::RUBY_PLATFORM == "java"
    spec.platform = "java"
    spec.add_development_dependency "activerecord-jdbcsqlite3-adapter"
  else
    spec.add_development_dependency "sqlite3", ">= 1.4"
  end

  spec.add_development_dependency "timecop"
end
