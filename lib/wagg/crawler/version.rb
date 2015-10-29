# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 8
    PATCH = 2
    BUILD = 'pre5'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end