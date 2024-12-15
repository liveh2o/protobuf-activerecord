source "https://rubygems.org"

# Specify your gem's dependencies in protobuf-activerecord.gemspec
gemspec

platforms :jruby do
  gem "activerecord-jdbcsqlite3-adapter"
end

platforms :ruby do
  gem "sqlite3", ">= 1.4"
end

gem "benchmark-ips"

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"
gem "rspec-pride", ">= 3.1.0"

gem "simplecov"

gem "standard", "~> 1.3"
