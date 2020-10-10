# frozen_string_literal: true

require 'mini_racer'
require 'feedjira'
require 'httparty'

require 'wagg/utils/parser'

require 'wagg/crawler/news_summary'
require 'wagg/crawler/vote'
require 'wagg/crawler/comment'

module Wagg
  module Crawler
    # Since we take repeated snapshots of a news we need a versioning abstraction
    # which happens to be the statistics of the news
    class NewsStatistics
      attr_accessor :karma
      attr_accessor :positive_votes
      attr_accessor :negative_votes
      attr_accessor :anonymous_votes
      attr_accessor :num_clicks
      attr_accessor :num_comments

      def num_votes
        if @positive_votes.nil? && @negative_votes.nil?
          @num_votes
        else
          @positive_votes + @negative_votes
        end
      end

      def num_votes=(num_votes = nil)
        @num_votes = num_votes if @positive_votes.nil? && @negative_votes.nil?
      end


      def initialize(snapshot_timestamp = nil)
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
      end
    end

    class News < NewsSummary
      # @!attribute [r] status
      #   @return [String] the status (published, queued, discarded) of the news
      # TODO: Figure whether this is really needed or can be extracted from the log_events attribute
      # attr_reader :status
      # @!attribute [r] karma_events
      #   @return [Hash] the list of karma events calculations of the news
      attr_reader :karma_events # Can be nil
      # @!attribute [r] log_events
      #   @return [Hash] the list of logged events of the news
      attr_reader :log_events # Can be nil
      # @!attribute [r] comments
      #   @return [ListComments] the list of comments of the news
      attr_reader :comments

      def initialize(id_extended, comments_mode = 'rss', snapshot_timestamp = nil)
        @id_extended = id_extended
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        @raw_data = get_data(format(::Wagg::Constants::News::MAIN_URL, id_extended: @id_extended))
        summary_item = @raw_data.css('div#newswrap > div.news-summary')

        # parse_summary
        super(summary_item, snapshot_timestamp)

        parse_log
        parse_votes
        parse_comments(comments_mode)
      end

      class << self
        def parse(id_extended, comments_mode = 'rss')
          news = News.new(id_extended, comments_mode)

          news
        end
      end

      def get_data(uri, retriever = nil, retriever_type = ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['news'])
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

      def parse_log
        log_uri = format(::Wagg::Constants::News::LOG_URL, id_extended: @id_extended)

        log_raw_data = get_data(log_uri)

        log_events_table_items = log_raw_data.css('div#voters > fieldset > div#voters-container > div')
        @log_events = parse_status_events(log_events_table_items)

        log_karma_events_script_items = log_raw_data.css('div#newswrap > script')
        @karma_events = parse_karma_events(log_karma_events_script_items)
      end

      def parse_status_events(events_table_items)
        status_events = {}

        events_table_items.each do |event_item|
          event_timestamp_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[1]/span/@data-ts')
          event_category_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[2]/text()')
          event_type_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[3]/strong/text()')
          event_author_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[4]/a/@href')

          event_author_matched = event_author_item.match(%r{\A/user/(?<author>.+)\z})

          status_events[event_timestamp_item] = {
            'category' => event_category_item,
            'type' => event_type_item,
            'author' => event_author_matched[:author]
          }
        end

        status_events
      end

      def parse_karma_events(script_items)
        # Cool stuff. Interpret JavaScript and store the results!
        context = MiniRacer::Context.new
        context.eval(script_items.at_xpath('.').text)
        k_coef_keys = context.eval('Object.keys(k_coef);')
        k_coef_values = context.eval('Object.values(k_coef);')
        karma_coef = Hash[k_coef_keys.zip k_coef_values]

        k_old_keys = context.eval('Object.keys(k_old);')
        k_old_values = context.eval('Object.values(k_old);')
        karma_old = Hash[k_old_keys.zip k_old_values]

        k_annotation_keys = context.eval('Object.keys(k_annotation);')
        k_annotation_values = context.eval('Object.values(k_annotation);')
        karma_annotation = Hash[k_annotation_keys.zip k_annotation_values]

        k_site_keys = context.eval('Object.keys(k_site);')
        k_site_values = context.eval('Object.values(k_site);')
        karma_site = Hash[k_site_keys.zip k_site_values]

        karma = {}
        karma_coef.each do |key, _value|
          karma[key] = {
            'coef' => karma_coef[key],
            'old' => karma_old[key],
            'annotation' => karma_annotation[key],
            'site' => karma_site[key]
          }
        end

        karma
      end

      def parse_comments(mode = 'rss')
        if mode == 'rss'
          @comments = ::Wagg::Crawler::ListComments.new(@id, @statistics.num_comments, mode)
        else
          @comments = ::Wagg::Crawler::ListComments.new(@id_extended, @statistics.num_comments, mode)
        end
      end

      private :parse_status_events, :parse_karma_events
    end
  end
end
