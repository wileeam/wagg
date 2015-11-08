# encoding: utf-8

require 'wagg/utils/constants'

module Wagg
  module Utils

    class Configuration
      attr_accessor :retrieval_delay
      attr_accessor :retrieval_page_type

      def initialize
        @retrieval_delay = Hash.new
        @retrieval_delay['default'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['default']
        @retrieval_delay['page'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['page']
        @retrieval_delay['news'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['news']
        @retrieval_delay['comment'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['comment']
        @retrieval_delay['vote'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['vote']
        @retrieval_delay['author'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['author']

        @retrieval_page_type = Hash.new
        @retrieval_page_type['discarded'] = Wagg::Utils::Constants::RETRIEVAL_PAGE_TYPE['discarded']
        @retrieval_page_type['published'] = Wagg::Utils::Constants::RETRIEVAL_PAGE_TYPE['published']
      end
    end

  end
end
