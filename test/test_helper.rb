# frozen_string_literal: true

require 'coveralls'
Coveralls.wear!

# require 'pry'
# require 'sinderella'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'wagg'

require 'minitest/autorun'
