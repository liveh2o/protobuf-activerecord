require 'rubygems'
require 'bundler'

require 'minitest/spec'
require 'minitest/autorun'

require 'mocha'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

Bundler.require(:default, :development, :test)

require 'support/db'
require 'support/models'
require 'support/protobuf'
