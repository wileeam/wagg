# encoding: utf-8

require 'wagg/utils/functions'
require 'wagg/utils/configuration'

require 'wagg/crawler/page'
require 'wagg/crawler/author'


module Wagg

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Utils::Configuration.new
      yield(configuration) if block_given?
    end

    def page(begin_interval=1, end_interval=begin_interval)
      Crawler::Page.parse(begin_interval,end_interval)
    end

    def author(name)
      Crawler::Author.parse(name)
    end

    def news(news_url, with_comments=FALSE, with_votes=FALSE)
      Crawler::News.parse(news_url, with_comments, with_votes)
    end

    def comment(comment_id, with_votes=FALSE)
      Crawler::Comment.parse_by_id(comment_id, with_votes)
    end

    def votes_for_news(news_id)
      Crawler::Vote.parse_news_votes(news_id)
    end

    def votes_for_comment(comment_id)
      Crawler::Vote.parse_comment_votes(comment_id)
    end
  end

end
