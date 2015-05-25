# encoding: utf-8

require 'wagg/crawler/news'

module Wagg
  module Crawler
    class Page

      class << self
        def parse(item, begin_interval=1, end_interval='all', only_summaries=FALSE)
          news_list = Array.new

          # Retrieve main list of news summaries DOM subtree
          news_items = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')

          # Figure out the interval of news items to retrieve in the page
          if begin_interval < 1 then
            nil
          end
          if end_interval != 'all' and begin_interval > end_interval
            nil
          end

          # Parse list of news summaries
          news_items.each do |n|
            news_object = only_summaries ? Wagg::Crawler::News.parse_summary(n) : Wagg::Crawler::News.parse(n,FALSE,FALSE)
            puts news_object
            exit(-1)
            news_list.push(news_object)
          end

          news_list
        end

        def parse_summaries(item)
          Wagg::Crawler::Page.parse(item,TRUE)
        end
      end
    end
  end
end