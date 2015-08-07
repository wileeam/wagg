# encoding: utf-8

require 'benchmark'

require 'wagg/utils/constants'
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
      Wagg::Crawler::Crawler::page_interval(begin_interval, end_interval, with_comments, with_votes)
    end

    def crawl_page_single(item, with_comments=FALSE, with_votes=FALSE)
      Wagg::Crawler::Crawler::page_single(item, with_comments, with_votes)
    end

    def crawl_news(url, with_comments=FALSE, with_votes=FALSE)
      Wagg::Crawler::Crawler::news(url, with_comments, with_votes)
    end

    def crawl_news_for_comments(item)

    end

  end

end

test_url = 'https://www.meneame.net/story/descubren-restos-arqueologicos-tarragona-unos-14-000-anos'
page_init_interval = 45
page_end_interval = 45
with_comments = TRUE
with_votes = TRUE
Wagg.crawl_news(test_url, with_comments, with_votes)
Wagg.crawl_page_interval(page_init_interval, page_end_interval, with_comments, with_votes)
