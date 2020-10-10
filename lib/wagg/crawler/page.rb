# encoding: UTF-8

module Wagg
  module Crawler
    class Page
      attr_reader :index
      attr_reader :news_list

      attr_reader :min_timestamp, :max_timestamp

      def initialize(index, type = ::Wagg::Constants::News::STATUS_TYPE['published'])
        @index = index

        @snapshot_timestamp = Time.now.utc
        @raw_data = get_data(format(::Wagg::Constants::Page::MAIN_URL[type], page:@index))

        #parse_summaries(type)
        @news_list = parse_summaries(type)
        #@min_timestamp, @max_timestamp = parse_timestamps
      end

      class << self
        def parse(index, type='published')
          page = Page.new(index, type)

          page
        end
      end

      def get_data(uri, retriever=nil, retriever_type=::Wagg::Constants::Retriever::RETRIEVAL_TYPE['page'])
        if retriever.nil?
          local_retriever = ::Wagg::Utils::Retriever.instance
          credentials = ::Wagg::Settings.configuration.credentials
        else
          credentials = ::Wagg::Settings.configuration.credentials
        end

        agent = local_retriever.agent(retriever_type)
        page = agent.get uri
        # page.encoding = 'utf-8'
        # page.body.force_encoding('utf-8')
        page
      end

      def parse_summaries(type = ::Wagg::Constants::News::STATUS_TYPE['published'])
        if @raw_data.nil?
          page_uri = format(::Wagg::Constants::Page::MAIN_URL[type], page:@index)
          page_raw_data = get_data(page_uri)
        else
          page_raw_data = @raw_data
        end

        page_summaries_items = page_raw_data.css('div#newswrap > div.news-summary')

        summaries = []
        page_summaries_items.each do |summary_item|
          summary = ::Wagg::Crawler::NewsSummary.new(summary_item, @snapshot_timestamp)

          summaries << summary
        end

        summaries
      end

    end
  end
end

