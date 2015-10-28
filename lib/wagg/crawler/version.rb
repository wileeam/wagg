# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 7
    PATCH = 1
    BUILD = 'pre4'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end