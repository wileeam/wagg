# encoding: utf-8

# @author Guillermo Rodríguez Cano <gurc@kth.se>

require 'wagg/utils/functions'
require 'wagg/utils/configuration'

require 'wagg/crawler/page'
require 'wagg/crawler/author'


module Wagg

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Wagg::Utils::Configuration.new
  end

  def self.reset
    @configuration = Wagg::Utils::Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  class << self

    # Parse the summaries of the news for the given page interval
    # @param type [String] the status of desired news
    # @param intervals [{FixNum => FixNum}] the intervals of the pages with the desired news
    # @return [nil] the parsed desired news
    def page(type='published', **intervals)
      intervals.has_key?(:begin_interval) ? begin_interval = intervals[:begin_interval] : begin_interval = 1
      intervals.has_key?(:end_interval) ? end_interval = intervals[:end_interval] : end_interval = begin_interval

      Crawler::Page.parse_interval(begin_interval, end_interval, type)
    end

    def author(name)
      Crawler::Author.parse(name)
    end

    def news(news_url)
      Crawler::News.parse(news_url)
    end

    def comment(comment_id)
      Crawler::Comment.parse_by_id(comment_id)
    end

    def votes_for_news(news_id)
      Crawler::Vote.parse_news_votes(news_id)
    end

    def votes_for_comment(comment_id)
      Crawler::Vote.parse_comment_votes(comment_id)
    end
  end

end
