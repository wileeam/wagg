# encoding: utf-8

require 'benchmark'

#require 'wagg/crawler/page'
require 'wagg/crawler/crawler'

module Wagg
  class << self

    def crawl(initial_date=(Time.now + (30*24*60*60)), end_date=(initial_date + (30*24*60*60)))

      # News < 30 days are always open for votes/comments
      # News >= 30 days are closed for votes and comments
      # Votes information is available up to 30 days after the last comment

    end

    def crawl_interval(begin_interval,end_interval,summaries=FALSE)
      Wagg::Crawler::Crawler::parse_page_interval(begin_interval,end_interval,summaries)
    end

    def crawl_single(item)
      Wagg::Crawler::Crawler::parse_single(item)
    end

    def dummy
      Benchmark.bm(7) do |x|
          x.report("::") {
            puts Wagg::Crawler::Crawler.parse_page_interval(3,3,FALSE)
          }
        end
      end
  end

end