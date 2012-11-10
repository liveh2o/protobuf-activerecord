source 'https://rubygems.org'

# Specify your gem's dependencies in protobuf-activerecord.gemspec
gemspec

gem 'builder', '~> 3.0.4' # Builder 3.1.x is not supported by Active Record
                          # and Bundler has trouble resolving the dependency
                          # with Geminabox.

gem 'timecop', '~> 0.3.5', :group => :development # Timecop 0.4.x is has a bug
                                                  # when dealing with timezones
                                                  # on Time objects.
