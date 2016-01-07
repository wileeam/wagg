# encoding: utf-8

require 'feedjira'

require 'wagg/utils/constants'

module Wagg
  module Utils

    class Configuration
      attr_accessor :retrieval_delay
      attr_accessor :retrieval_page_type
      attr_accessor :retrieval_credentials

      def initialize
        @retrieval_delay = Hash.new
        @retrieval_delay['default'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['default']
        @retrieval_delay['page'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['page']
        @retrieval_delay['news'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['news']
        @retrieval_delay['comment'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['comment']
        @retrieval_delay['vote'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['vote']
        @retrieval_delay['author'] = Wagg::Utils::Constants::RETRIEVAL_DELAY['author']

        @retrieval_page_type = Hash.new
        @retrieval_page_type['discarded'] = Wagg::Utils::Constants::NEWS_STATUS_TYPE['discarded']
        @retrieval_page_type['queued'] = Wagg::Utils::Constants::NEWS_STATUS_TYPE['queued']
        @retrieval_page_type['published'] = Wagg::Utils::Constants::NEWS_STATUS_TYPE['published']

        @retrieval_credentials = Hash.new
        @retrieval_credentials['username'] = nil
        @retrieval_credentials['password'] = nil
      end
    end

    class Feedjira::Parser::RSSEntry
      element 'meneame:comment_id', :as => :comment_id
      element 'meneame:link_id',    :as => :comment_news_id
      element 'meneame:order',      :as => :comment_news_index
      element 'meneame:user',       :as => :comment_author_name
      element 'meneame:votes',      :as => :comment_votes_count
      element 'meneame:karma',      :as => :comment_karma
      element 'meneame:url',        :as => :comment_news_url_internal
    end

  end
end
