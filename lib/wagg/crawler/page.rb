# frozen_string_literal: true

module Wagg
  module Crawler
    class Page
      attr_reader :index, :news_list, :min_timestamp, :max_timestamp

      def initialize(index, type = ::Wagg::Constants::News::STATUS_TYPE['published'])
        @index = index

        @snapshot_timestamp = Time.now.utc
        @raw_data = get_data(format(::Wagg::Constants::Page::MAIN_URL[type], page: index))

        @news_list = parse_summaries(type)
        # @min_timestamp, @max_timestamp = parse_timestamps
      end

      class << self
        def parse(index, type = 'published')
          Page.new(index, type)
        end
      end

      def get_data(uri, custom_retriever = nil)
        retriever = if custom_retriever.nil?
                      ::Wagg::Utils::Retriever.instance
                    else
                      custom_retriever
                    end

        retriever.get(uri, ::Wagg::Constants::Retriever::AGENT_TYPE['page'], false)
      end
      
      def get_summary(index, raw = false)
        if index <= ::Wagg::Constants::Page::MAX_SUMMARIES
          if raw
            raw_summaries = get_raw_summaries_list
            summary = raw_summaries[index]
          else
            summary = @news_list[index]
          end

          summary
        end
      end

      def parse_summaries(type = ::Wagg::Constants::News::STATUS_TYPE['published'])
        if @raw_data.nil?
          page_uri = format(::Wagg::Constants::Page::MAIN_URL[type], page: @index)
          @raw_data = get_data(page_uri)
        end

        page_summaries_items = get_raw_summaries_list
        summaries = page_summaries_items.map { |summary_item| ::Wagg::Crawler::NewsSummary.new(summary_item, @snapshot_timestamp) }

        summaries
      end

      def get_raw_summaries_list
        @raw_data.css('div#newswrap > div.news-summary')
      end

      private :parse_summaries, :get_raw_summaries_list
    end
  end
end
