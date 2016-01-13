# encoding: utf-8

module Wagg
  module Version
    MAJOR = 0
    MINOR = 9
    PATCH = 10
    BUILD = 'beta'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end