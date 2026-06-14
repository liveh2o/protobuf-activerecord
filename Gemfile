source "https://rubygems.org"

# Specify your gem's dependencies in protobuf-activerecord.gemspec
gemspec

platforms :jruby do
  # Pre-release is required to run tests on JRuby
  gem "activerecord-jdbcsqlite3-adapter", ">= 80.0.pre1"
end

platforms :ruby do
  gem "sqlite3", ">= 2.9"
end

gem "benchmark-ips"

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"
gem "rspec-pride", ">= 3.1.0"

gem "simplecov"

gem "standard", "~> 1.3"
