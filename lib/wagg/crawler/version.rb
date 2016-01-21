# encoding: utf-8

module Wagg
  module Version
    MAJOR = 1
    MINOR = 0
    PATCH = 3
    BUILD = 'pre'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end