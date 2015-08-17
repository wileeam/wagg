# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 4
    PATCH = 0
    BUILD = 'pre1'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end