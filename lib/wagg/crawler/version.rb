# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 5
    PATCH = 0
    BUILD = 'pre2'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end