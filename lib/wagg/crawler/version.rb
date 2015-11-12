# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 9
    PATCH = 1
    BUILD = 'alpha'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end