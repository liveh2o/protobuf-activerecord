# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "protobuf/active_record/version"

Gem::Specification.new do |spec|
  spec.name = "protobuf-activerecord"
  spec.version = Protobuf::ActiveRecord::VERSION
  spec.authors = ["Adam Hutchison"]
  spec.email = ["liveh2o@gmail.com"]

  spec.summary = "Google Protocol Buffers integration for Active Record"
  spec.description = "Provides the ability to create Active Record objects from Protocol Buffer messages and vice versa."
  spec.homepage = "http://github.com/liveh2o/protobuf-activerecord"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  ##
  # Dependencies
  #
  spec.add_dependency "activerecord", "~> 7.1.0"
  spec.add_dependency "activesupport", "~> 7.1.0"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "heredity", ">= 0.1.1"
  spec.add_dependency "protobuf", ">= 3.0"
end
