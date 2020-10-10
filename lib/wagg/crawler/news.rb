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
      # @!attribute [r] votes
      #   @return [Array] the list of votes of the news
      attr_reader :votes
      # @!attribute [r] comments
      #   @return [Array] the list of comments of the news
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

      def parse_votes
        min_page = 1
        max_page = min_page
        votes_uri = format(::Wagg::Constants::News::VOTES_QUERY_URL, id: @id, page: min_page)
        votes_list = []

        votes_raw_data = get_data(votes_uri)
        pages_item = votes_raw_data.css('div.pages > a')
        pages_item.each do |page_item|
          num_page = ::Wagg::Utils::Functions.text_at_xpath(page_item, './text()').to_i
          max_page = num_page if max_page < num_page
        end

        (min_page..max_page).each do |page|
          snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          votes_uri = format(::Wagg::Constants::News::VOTES_QUERY_URL, id: @id, page: page)
          votes_raw_data = get_data(votes_uri)

          #  div.voters-list > div > a
          votes_list_item = votes_raw_data.css('div.voters-list > div')
          votes_list_item.each do |vote_item|
            author_name_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/@href')
            author_name_matched = author_name_item.match(%r{\A/user/(?<author>.+)\z})
            author_name = author_name_matched[:author]
            author_id_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/img/@src')
            author_id_matched = author_id_item.match(%r{\Ahttps\:/{2}mnmstatic\.net/cache/\d{2}/\d{2}/(?<id>\d+)\-\d+\-\d{2}\.jpg\z})
            author_id = (author_id_matched[:id] unless author_id_matched.nil? || author_id_matched[:id].nil?)

            timestamp_weight_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/@title')
            timestamp_weight_matched = timestamp_weight_item.match(::Wagg::Constants::Vote::NEWS_REGEX)
            vote_hash = timestamp_weight_matched.named_captures
            if vote_hash['datetime'].nil? && !vote_hash['time'].nil?
              now = DateTime.now.new_offset # Current datetime in UTC
              vote_date = DateTime.strptime(now.strftime('%d-%m-%Y') + ' ' + vote_hash['time'], '%d-%m-%Y %H:%M %Z')
            else
              vote_date = DateTime.strptime(vote_hash['datetime'], '%d-%m-%Y %H:%M %Z')
            end
            if vote_hash[:weight]
              # Positive votes have a weight
              vote_type = ::Wagg::Constants::Vote::NEWS_TYPE['positive']
              vote_weight = vote_hash[:weight].to_i
            else
              # Negative votes do NOT have a weight
              vote_weight_type = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './span/text()')
              vote_type = ::Wagg::Constants::Vote::NEWS_TYPE['negative']
              vote_weight = ::Wagg::Constants::Vote::NEWS_NEGATIVE_WEIGHT[vote_weight_type]
            end

            vote = ::Wagg::Crawler::Vote.new(author_name, author_id, vote_type, vote_weight, vote_date, snapshot_timestamp)
            votes_list << vote
          end
        end

        @votes = ::Wagg::Crawler::NewsVotes.new(votes_list)
      end

      def parse_comments(mode = 'rss')
        comments_hash = {}

        case mode
        when 'rss'
          snapshot_timestamp = Time.now.utc

          comments_rss_uri = format(::Wagg::Constants::News::COMMENTS_RSS_URL, id: @id)
          comments_xml = HTTParty.get(comments_rss_uri).body
          comments_rss = Feedjira.parse(comments_xml, parser: Feedjira::Parser::Wagg::CommentsList)
          comments_rss.entries.each do |comment_rss|
            comment = ::Wagg::Crawler::Comment.new(comment_rss, 'rss', snapshot_timestamp)
            comments_hash[comment.index] = comment
          end
        when 'html'
          num_pages, remaining_comments = @statistics.num_comments.divmod(::Wagg::Constants::News::COMMENTS_URL_MAX_PAGE)
          num_pages += 1 if remaining_comments > 0
          (1..num_pages).each do |page|
            snapshot_timestamp = Time.now.utc

            comments_html_uri = format(::Wagg::Constants::News::COMMENTS_URL, {id_extended: @id_extended, page: page})
            comments_html_raw_data = get_data(comments_html_uri)
            comments_html_list_items = comments_html_raw_data.css('div#newswrap > div#comments-top > ol > li')
            comments_html_list_items.each do |comment_item|
              comment = ::Wagg::Crawler::Comment.new(comment_item, 'html', snapshot_timestamp)
              comments_hash[comment.index] = comment
            end
          end

        else
          raise 'News\' comments parsing mode not supported yet unfortunately'
        end

        @comments = comments_hash
      end

      private :parse_status_events, :parse_karma_events
    end
  end
end
