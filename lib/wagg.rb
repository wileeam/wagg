# encoding: utf-8

require 'benchmark'

require 'wagg/utils/constants'
require 'wagg/crawler/crawler'
require 'wagg/crawler/comment'

#require 'wagg/crawler/page'

module Wagg
  class << self

    def crawl_interval_by_time(initial_date=(Time.now + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME), end_date=(initial_date + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME + Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME))

      # News < 30 days are always open for votes/comments
      # News >= 30 days are closed for votes and comments
      # Votes information is available up to 30 days after the last comment

      puts initial_date

      puts end_date

    end

    def crawl_interval(begin_interval, end_interval, only_summaries=TRUE)
      Wagg::Crawler::Crawler::page_interval(begin_interval, end_interval, only_summaries)
    end

    def crawl_single(item)
      Wagg::Crawler::Crawler::page_single(item, FALSE)
    end

    def crawl_news(url, votes=FALSE, comments=FALSE)
      Wagg::Crawler::Crawler::news(url, votes, comments)
    end

    def crawl_news_for_comments(item)

    end

    def dummy(begin_interval=63, end_interval=63,only_summaries=FALSE)
      Benchmark.bm(7) do |x|
          x.report("::") {
            #Wagg::Crawler::Crawler.parse_page_interval(begin_interval, end_interval, only_summaries).each do |news|
            #  puts news
            Wagg::Crawler::Crawler.parse_page_single(begin_interval, only_summaries).each do |news|
              puts news
            end
          }
      end
    end

    def dummy_news(url)
      Wagg::Crawler::Crawler.news(url,TRUE,TRUE)
    end

  end

end

