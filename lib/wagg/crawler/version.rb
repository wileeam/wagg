# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 3
    PATCH = 1
    BUILD = 'pre0'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end