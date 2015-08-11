# encoding: utf-8

require 'benchmark'

require 'wagg/utils/constants'
require 'wagg/utils/functions'

require 'wagg/crawler/crawler'
require 'wagg/crawler/comment'

module Wagg
  class << self

    def crawl_interval_by_time(initial_date=(Time.now + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME), end_date=(initial_date + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME + Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME))

      # News < 30 days are always open for votes/comments
      # News >= 30 days are closed for votes and comments
      # Votes information is available up to 30 days after the last comment

      puts initial_date

      puts end_date

    end

    def crawl_page_interval(begin_interval, end_interval, with_comments=FALSE, with_votes=FALSE)
      Wagg::Crawler.page_interval(begin_interval, end_interval, with_comments, with_votes)
    end

    def crawl_page_single(item, with_comments=FALSE, with_votes=FALSE)
      Wagg::Crawler.page_single(item, with_comments, with_votes)
    end

    def crawl_author(username)
      Wagg::Crawler.author(username)
    end

    def crawl_news(url, with_comments=FALSE, with_votes=FALSE)
      Wagg::Crawler.news(url, with_comments, with_votes)
    end

    def crawl_news_for_comments(item)

    end

    # Returns the list of URLs available in each page within the provided range
    #
    # @param begin_page_interval [Integer] the interval leftmost limit
    # @param end_page_interval [Integer] the interval rightmost limit
    # @return [Hash] the list of url strings indexed by
    def get_news_urls(begin_page_interval, end_page_interval)
      Wagg::Crawler.get_news_urls(begin_page_interval, end_page_interval)
    end

  end

end
