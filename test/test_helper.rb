# encoding: utf-8

require 'coveralls'
Coveralls.wear!

# require 'pry'
# require 'sinderella'

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "wagg"

require "minitest/autorun"
