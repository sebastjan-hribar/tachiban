$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tachiban'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'timecop'
require 'hanami/model'
require 'setup.rb'
include Hanami::Tachiban
