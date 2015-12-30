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
          page_begin_index, page_end_index = Utils::Functions.filter_page_interval(begin_index, end_index, type)

          page_list = Hash.new

          (page_begin_index..page_end_index).each do |page_index|
            page_list[page_index] = Page.new(page_index, type)
          end

          page_list
        end

        def parse_interval(begin_index=1, end_index=begin_index, type='published')
          Page.parse(begin_index, end_index, type)
        end
      end

    end
  end
end
