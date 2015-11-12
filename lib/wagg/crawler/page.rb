# encoding: utf-8

require 'wagg/crawler/news'

module Wagg
  module Crawler
    class Page

      attr_reader :index
      attr_reader :news_list

      def initialize(index, type='published')
        @index = index
        @news_list = parse_summaries(type)
      end

      # Returns the list of URLs available in the page
      #
      # @return [Array] the list of url strings.
      def news_urls
        @news_list.keys
      end

      def to_s
        res = "PAGE #%{index}\n" % {index:@index}
        @news_list.keys.each do |url|
            res += "  - %{url} " % {url:url}
            res += @news_list[url].open? ? "(open)" : "(closed)"
            res += "\n"
        end

        res
      end

      def parse_summaries(type='published')
        Utils::Retriever.instance.agent('page', Wagg.configuration.retrieval_delay['page'])

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

      private :parse_summaries


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
