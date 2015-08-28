# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 6
    PATCH = 1
    BUILD = 'pre3'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end