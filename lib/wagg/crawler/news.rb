# encoding: UTF-8

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
      # @!attribute [r] karma
      #   @return [Integer] the karma of the news
      attr_accessor :karma
      # @!attribute [r] positive_votes
      #   @return [Integer] the number of positive votes of the news
      attr_accessor :positive_votes
      # @!attribute [r] negative_votes
      #   @return [Integer] the number of negative votes of the news
      attr_accessor :negative_votes
      # @!attribute [r] anonymous_votes
      #   @return [Integer] the number of anonymous votes of the news
      attr_accessor :anonymous_votes
      # @!attribute [r] num_clicks
      #   @return [Integer] the number of clicks of the news
      attr_accessor :num_clicks
      # @!attribute [r] num_comments
      #   @return [Integer] the number of comments of the news
      attr_accessor :num_comments
      # @!attribute [r] num_votes
      #   @return [Integer] the number of positive and negative votes of the news
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

      def initialize(snapshot_timestamp = nil, json_data = nil)
        if json_data.nil?
          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        else
          @karma = json_data.karma
          @positive_votes = json_data.positive_votes
          @negative_votes = json_data.negative_votes
          @anonymous_votes = json_data.anonymous_votes
          @num_clicks = json_data.num_clicks
          @num_comments = json_data.num_comments

          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        end
      end

      class << self
        def from_json(string)
          os_object = JSON.parse(string, {:object_class => OpenStruct, :quirks_mode => true})

          # Some validation that we have the right object
          if os_object.type == self.name.split('::').last
            data = os_object.data

            snapshot_timestamp = Time.at(os_object.timestamp).utc

            NewsStatistics.new(snapshot_timestamp, data)
          end
        end
      end

      def as_json(options = {})
        {
          type: self.class.name.split('::').last,
          timestamp: ::Wagg::Utils::Functions.timestamp_to_text(@snapshot_timestamp, '%s').to_i,
          data: {
            karma: @karma,
            positive_votes: @positive_votes,
            negative_votes: @negative_votes,
            anonymous_votes: @anonymous_votes,
            num_clicks: @num_clicks,
            num_comments: @num_comments
          }
        }
      end

      def to_json(*options)
        as_json(*options).to_json(*options)
      end

    end

    class News < NewsSummary
      # @!attribute [r] status
      #   @return [String] the status (published, queued, discarded) of the news
      # TODO: Figure whether this is really needed or can be extracted from the log_events attribute
      # attr_reader :status
      # @!attribute [r] tags
      #   @return [Array] the list of tags of the news
      attr_reader :tags
      # @!attribute [r] karma_events
      #   @return [Hash] the list of karma events calculations of the news
      attr_reader :karma_events # Can be nil
      # @!attribute [r] log_events
      #   @return [Hash] the list of logged events of the news
      attr_reader :log_events # Can be nil
      # @!attribute [r] comments
      #   @return [ListComments] the list of comments of the news
      attr_reader :comments

      # @param [String] id_extended
      # @param [String] comments_mode
      # @param [nil] snapshot_timestamp
      # @param [String] json_data
      def initialize(id_extended, comments_mode = 'rss', snapshot_timestamp = nil, json_data = nil, summary_object = nil)
        if json_data.nil? && summary_object.nil?
          @id_extended = id_extended
          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          @raw_data = get_data(format(::Wagg::Constants::News::MAIN_URL, id_extended: @id_extended))

          # TODO: Detect here if it is an article category news or not
          # "#container > div:nth-child(1) > div > div.col-md-8.col-md-offset-1 > div"
          if @raw_data.at_css('div#newswrap').nil? && !@raw_data.at_css('div.story-blog').nil?
            summary_item = @raw_data.at_css('div.story-blog > div.row')
          else
            # div#newswrap > div.news-summary
            summary_item = @raw_data.at_css('div#newswrap > div.news-summary')

            # div#newswrap > div.news-summary > div.news-body > div.center-content > span
            # document.querySelector("#newswrap > div.news-summary > div > div.center-content > span")
            tags_item = @raw_data.at_css('div#newswrap > div.news-summary > div.news-body > div.center-content > span')
            more_tags_item = @raw_data.at_css('div#newswrap > div.news-summary > div > div.center-content > span')
            puts more_tags_item
            puts tags_item
            parse_tags(tags_item)
            # parse_summary
            super(summary_item, @snapshot_timestamp)
          end

          parse_log
          parse_votes
          parse_comments(comments_mode)
        elsif summary_object.nil?
          @id = json_data.id
          @id_extended = json_data.id_extended
          @title = json_data.title
          @author = ::Wagg::Crawler::FixedAuthor.from_json(json_data.author)
          @link = json_data.link
          @permalink_id = json_data.permalink_id
          @body = json_data.body
          @timestamps = json_data.timestamps.to_h.map { |k, v| [k, Time.at(v).utc.to_datetime] }.to_h
          @category = json_data.category
          @statistics = ::Wagg::Crawler::NewsStatistics.from_json(json_data.statistics)

          @tags = json_data.tags
          @karma_events = json_data.karma_events.to_h
          karma_events_list = @karma_events[:karma].map { |karma_event| [karma_event[0], karma_event[1].to_h]  }
          @karma_events[:karma] = karma_events_list
          @log_events = json_data.log_events.to_h.map { |k, v| [k.to_s.to_i, v.to_h] }.to_h

          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        else
          @id = summary_object.id
          @id_extended = summary_object.id_extended
          @title = summary_object.title
          @author = summary_object.author
          @link = summary_object.link
          @permalink_id = summary_object.permalink_id
          @body = summary_object.body
          @timestamps = summary_object.timestamps
          @category = summary_object.category
          @statistics = summary_object.statistics
          # @votes = summary_object.votes

          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        end
      end

      class << self
        def parse(id_extended, comments_mode = 'rss')
          news = News.new(id_extended, comments_mode)

          news
        end

        def from_json(string)
          os_object = JSON.parse(string, {:object_class => OpenStruct, :quirks_mode => true})

          # Some validation that we have the right object
          if os_object.type == self.name.split('::').last
            data = os_object.data

            snapshot_timestamp = Time.at(os_object.timestamp).utc

            News.new(nil, nil, snapshot_timestamp, data, nil)
          end
        end

        def from_summary(summary)
          if summary.class.name.split('::').last == 'NewsSummary'
            snapshot_timestamp = summary.snapshot_timestamp

            News.new(nil, nil, snapshot_timestamp, nil, summary)
          end
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

      def parse_tags(tags_item)
        tags_items_list = tags_item.css('a')

        tags = []
        tags_items_list.each do |tag_item|
          tag_href = ::Wagg::Utils::Functions.text_at_xpath(tag_item, './@href')
          if tag_href.match?(::Wagg::Constants::Tag::NAME_REGEX)
            tag_href_matched = tag_href.match(::Wagg::Constants::Tag::NAME_REGEX)
            tag = CGI.unescape(tag_href_matched[:tag].strip).unicode_normalize(:nfkc)
          end
          tags << tag
        end

        @tags = tags
      end

      def parse_log
        log_uri = format(::Wagg::Constants::News::LOG_URL, id_extended: @id_extended)

        log_raw_data = get_data(log_uri)

        # Closed news will lack this information
        if log_raw_data.at('div#voters > fieldset > div#voters-container > div')
          log_events_table_items = log_raw_data.css('div#voters > fieldset > div#voters-container > div')
          @log_events = parse_status_events(log_events_table_items)
        else # ::Wagg::Utils::Functions.text_at_css(log_raw_data, 'div#voters > fieldset > div#voters-container') == 'no hay registros'
          @log_events = nil
        end

        # Very old news won't have this information
        if log_raw_data.at('div#newswrap > script')
          log_karma_events_script_items = log_raw_data.css('div#newswrap > script')
          # log_karma_events_script_items = log_raw_data.xpath('div[@id="container"]/div//script')
          @karma_events = parse_karma_events(log_karma_events_script_items)
        else
          @karma_events = nil
        end
      end

      def parse_status_events(events_table_items)
        status_events = []

        events_table_items.each do |event_item|
          event_timestamp_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[1]/span/@data-ts')
          event_timestamp = event_timestamp_item.to_i

          event_category = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[2]/text()')

          event_type = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[3]/strong/text()')

          event_author_item = ::Wagg::Utils::Functions.text_at_xpath(event_item, './div[4]/a/@href')
          if event_author_item.match?(%r{\A/user/(?<author>.+)\z})
            event_author_matched = event_author_item.match(%r{\A/user/(?<author>.+)\z})
            event_author = event_author_matched[:author]
          else
            event_author = nil
          end

          event_data = {
            'category' => event_category,
            'type' => event_type,
            'author' => event_author
          }
          status_events.append([Time.at(event_timestamp).to_datetime, event_data])
        end

        status_events
      end

      def parse_karma_events(script_items)
        # First parse JSON of events at ::Wagg::Constants::News::KARMA_STORY_JSON_URL
        story_events_uri = format(::Wagg::Constants::News::KARMA_STORY_JSON_URL, id: @id)

        story_events_raw_data = get_data(story_events_uri)

        story_events_json = JSON.parse(story_events_raw_data.body, {:quirks_mode => true})

        story_events = {}
        story_events_json.each do |story|
          label = story['label']
          data = story['data']

          story_events[label] = data.map { |event| [Time.at(event[0] / 1000.0).to_datetime, event[1].to_i] }
        end

        # Thereafter parse the extra attributes of each 'karma' event
        # And cool stuff by the way, interpret JavaScript and store the results!
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

        karma_events = {}
        karma_coef.each do |key, _value|
          karma_events[Time.at(key.to_i).to_datetime] = {
            'coef' => karma_coef[key],
            'old' => karma_old[key],
            'annotation' => karma_annotation[key],
            'site' => karma_site[key]
          }
        end

        # Finally merge the extra attributes of each 'karma' event with the events' JSON
        story_karma_events = []
        story_events['karma'].each do |karma_event|
          event = karma_events[karma_event[0]]
          event['current'] = karma_event[1]
          story_karma_events.append([karma_event[0], event])
        end
        story_events['karma'] = story_karma_events

        story_events
      end

      def parse_comments(mode = 'rss')
        if mode == 'rss'
          @comments = ::Wagg::Crawler::ListComments.new(@id, @statistics.num_comments, mode)
        else
          @comments = ::Wagg::Crawler::ListComments.new(@id_extended, @statistics.num_comments, mode)
        end
      end

      private :parse_status_events, :parse_karma_events

      def as_json(options = {})
        {
          type: self.class.name.split('::').last,
          timestamp: ::Wagg::Utils::Functions.timestamp_to_text(@snapshot_timestamp, '%s').to_i,
          data: {
            id: @id.to_i,
            id_extended: @id_extended,
            title: @title,
            author: @author.to_json,
            link: @link,
            permalink_id: @permalink_id,
            body: body,
            timestamps: ::Wagg::Utils::Functions.hash_str_datetime_to_json(@timestamps, true),
            category: @category,
            statistics: @statistics.to_json,
            tags: @tags,
            karma_events: (@karma_events.nil? ? {} : @karma_events),
            log_events: (@log_events.nil? ? {} : @log_events),
            # comments: TODO
          }
        }
      end

      def to_json(*options)
        as_json(*options).to_json(*options)
      end

    end
  end
end
