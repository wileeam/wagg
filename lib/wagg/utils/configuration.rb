# encoding: utf-8

require 'wagg/utils/constants'

module Wagg
  module Utils

    class Configuration
      attr_accessor :retrieval_delay

      def initialize
        @retrieval_delay = Hash.new
        @retrieval_delay['default'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['default']
        @retrieval_delay['page'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['page']
        @retrieval_delay['news'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['news']
        @retrieval_delay['comment'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['comment']
        @retrieval_delay['vote'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['vote']
        @retrieval_delay['author'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['author']
      end
    end

  end
end
