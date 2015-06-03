# encoding: utf-8

require 'benchmark'

#require 'wagg/crawler/page'
require 'wagg/crawler/crawler'

module Wagg
  class << self

    def crawl_interval_by_time(initial_date=(Time.now + (30*24*60*60)), end_date=(initial_date + (30*24*60*60)))

      # News < 30 days are always open for votes/comments
      # News >= 30 days are closed for votes and comments
      # Votes information is available up to 30 days after the last comment

    end

    def crawl_interval(begin_interval, end_interval, only_summaries=TRUE)
      Wagg::Crawler::Crawler::parse_page_interval(begin_interval, end_interval, only_summaries)
    end

    def crawl_single(item)
      Wagg::Crawler::Crawler::parse_single(item)
    end

    def dummy(begin_interval=66, end_interval=66,only_summaries=TRUE)
      Benchmark.bm(7) do |x|
          x.report("::") {
            Wagg::Crawler::Crawler.parse_page_interval(begin_interval, end_interval, only_summaries).each do |news|
              puts news
            end
          }
      end

      exit(0)
    end

  end

end
