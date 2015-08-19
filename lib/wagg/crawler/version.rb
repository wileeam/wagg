# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 4
    PATCH = 2
    BUILD = 'pre1'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end