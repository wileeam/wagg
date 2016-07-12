# encoding: utf-8

module Wagg
  module Version
    MAJOR = 1
    MINOR = 1
    PATCH = 5
    BUILD = 'pre'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end