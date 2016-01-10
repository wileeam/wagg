# encoding: utf-8

require 'wagg/crawler/news'

module Wagg
  module Crawler
    class Page
      attr_reader :index, :news_list
      attr_reader :min_timestamp, :max_timestamp

      def initialize(index, type='published')
        @index = index
        @news_list = parse_summaries(type)
        @min_timestamp, @max_timestamp = parse_timestamps
      end

      # Returns the list of URLs available in the page
      #
      # @return [Array] the list of url strings.
      def news_urls
        @news_list.keys
      end

      def to_s
        res = "PAGE #%{index} :: (%{min} || %{max})\n" % {index:@index, min:Time.at(@min_timestamp), max:Time.at(@max_timestamp)}
        @news_list.keys.each do |url|
            res += "  - %{url} " % {url:url}
            res += "(%{voting}|%{commenting})\n" % {voting:@news_list[url].voting_open?.to_s, commenting:@news_list[url].commenting_open?.to_s}
        end

        res
      end

      def parse_summaries(type='published')
        page_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['page']

        page_item = Utils::Retriever.instance.get(Utils::Constants::PAGE_URL[type] % {page:@index}, 'page')
        news_summaries_list = Hash.new

        news_list_items = page_item.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')
        news_list_items.each do |news_item|
          news = News.parse_summary(news_item, page_retrieval_timestamp)
          news_summaries_list[news.urls['internal']] = news
        end

        news_summaries_list
      end

      def parse_timestamps
        news_timestamps_list = Array.new

        @news_list.each do |url, news|
          news_timestamps_list.push(news.timestamps['creation'])
        end
        news_timestamps_list.sort!

        return news_timestamps_list.first, news_timestamps_list.last
      end

      private :parse_summaries, :parse_timestamps


      class << self
        def parse(begin_index=1, end_index=begin_index, type='published')
          Page.parse_interval(begin_index, end_index, type)
        end

        def parse_interval(begin_index=1, end_index=begin_index, type='published')
          # We do not really need to check the interval limits
          #page_begin_index, page_end_index = Utils::Functions.filter_page_interval(begin_index, end_index, type)
          page_begin_index = begin_index
          page_end_index = end_index

          if begin_index <= end_index
            if begin_index < 1
              page_begin_index = 1
            end
            if end_index < 1
              page_end_index = 1
            end
          elsif begin_index > end_index
            if end_index < 1
              page_begin_index = 1
            end
            if begin_index < 1
              page_end_index = 1
            else
              page_end_index = begin_index
            end
          end

          page_list = Hash.new

          page_index = page_begin_index
          while page_index <= page_end_index && !(page = Page.new(page_index, type)).news_list.empty?
            page_list[page_index] = page
            page_index += 1
          end

          page_list
        end

        def filter_page_interval(begin_interval=1, end_interval='all', type='published')
          # Get first page of website for reference
          page_one = Retriever.instance.get(Constants::PAGE_URL[type] % {page:1}, 'main')
          # Find the DOM item containing the navigation buttons for pages
          max_end_interval_item = page_one.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " pages ")]')
          # Parse the maximum number of pages to a number
          # TODO: Can we do better than this (tested that there are pages with more than one 'nofollow')?
          max_end_interval = str_at_xpath(max_end_interval_item, './a[@rel="nofollow"]/text()').to_i

          filtered_begin_interval = begin_interval
          if begin_interval == 'all' || begin_interval > max_end_interval
            filtered_begin_interval = max_end_interval
          elsif begin_interval < 1
            filtered_begin_interval = 1
          end

          filtered_end_interval = end_interval
          if end_interval == 'all' || end_interval > max_end_interval
            filtered_end_interval = max_end_interval
          elsif end_interval < 1
            filtered_end_interval = 1
          end

          return filtered_begin_interval, filtered_end_interval
        end
      end

    end
  end
end
