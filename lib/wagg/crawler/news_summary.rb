# encoding: UTF-8

module Wagg
  module Crawler
    class NewsSummary
      # @!attribute [r] id
      #   @return [Fixnum] the unique id of the news
      attr_reader :id
      # @!attribute [r] id_extended
      #   @return [String] the extended id of the news
      attr_reader :id_extended
      # @!attribute [r] title
      #   @return [String] the title of the news
      attr_reader :title
      # @!attribute [r] author
      #   @return [FixedAuthor] the author of the news
      attr_reader :author
      # @!attribute [r] link
      #   @return [String] the link to the actual news
      attr_reader :link
      # @!attribute [r] permalink_id
      #   @return [String] the id to the permalink of the news
      attr_reader :permalink_id
      # @!attribute [r] body
      #   @return [String] the body of the news
      attr_reader :body
      # @!attribute [r] timestamps
      #   @return [Hash] the creation and publication (if available) timestamps of the news
      attr_reader :timestamps
      # @!attribute [r] category
      #   @return [String] the category of the news
      attr_reader :category
      # @!attribute [r] statistics
      #   @return [NewsStatistics] the statistics of the news
      attr_reader :statistics
      # @!attribute [r] votes
      #   @return [Array] the list of votes of the news
      def votes
        if @votes.nil?
          @votes = ::Wagg::Crawler::NewsVotes.parse(@id)
        else
          @votes
        end
      end

      def initialize(raw_data, snapshot_timestamp = nil)
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        @raw_data = raw_data

        # div.news-body
        id_item = @raw_data.css('div.news-body')
        parse_id(id_item)

        # div.news-body > div.news-details > div.news-details-main
        id_extended_item = @raw_data.css('div.news-body > div.news-details > div.news-details-main')
        parse_id_extended(id_extended_item)

        # div.news-body > div.center-content
        content_item = @raw_data.css('div.news-body > div.center-content')
        parse_content(content_item)

        # div.news-body > div.news-shakeit
        shakeit_item = @raw_data.css('div.news-body > div.news-shakeit')
        # div.news-body > div.news-details
        details_item = @raw_data.css('div.news-body > div.news-details')
        parse_statistics(shakeit_item, details_item)
        parse_permalink(details_item)
      end

      class << self
        def parse(raw_data, snapshot_timestamp)
          news_summary = NewsSummary.new(raw_data, snapshot_timestamp)

          news_summary
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

      def uri
        format(::Wagg::Constants::News::MAIN_URL % {id_extended:@id_extended})
      end

      def permalink
        format(::Wagg::Constants::News::MAIN_PERMALINK_URL % {permalink_id:@permalink_id})
      end

      def parse_votes
        @votes = ::Wagg::Crawler::NewsVotes.parse(@id) if !@id.nil? && @votes.nil?
      end
      
      # Private methods below

      def parse_id(id_item)
        @id = ::Wagg::Utils::Functions.text_at_xpath(id_item, './@data-link-id')
      end

      def parse_id_extended(id_extended_item)
        id_extended_href_item = ::Wagg::Utils::Functions.text_at_xpath(id_extended_item, './a/@href')
        id_extended_href_matched = id_extended_href_item.match(/\A\/story\/(?<id_extended>.+)/)
        @id_extended = id_extended_href_matched[:id_extended]
      end

      def parse_content(content_item)
        title_link_item = content_item.css('h2')
        # News' title
        title = ::Wagg::Utils::Functions.text_at_xpath(title_link_item, './a/text()')
        # News' link
        link = ::Wagg::Utils::Functions.text_at_xpath(title_link_item, './a/@href')
        @title = title
        @link = link

        author_timestamps_item = content_item.css('div.news-submitted')
        # Author's id
        author_id_items = ::Wagg::Utils::Functions.text_at_xpath(author_timestamps_item, './a/@class')
        author_id_matched = author_id_items.match(/\A.+\su\:(?<author_id>\d+)\z/)
        author_id = author_id_matched[:author_id]
        # Author's name
        author_name_item = ::Wagg::Utils::Functions.text_at_xpath(author_timestamps_item, './a/@href')
        author_name_matched = author_name_item.match(/\A\/user\/(?<author_name>.+)\z/)
        author_name = author_name_matched[:author_name]
        @author = ::Wagg::Crawler::FixedAuthor.new(author_name, author_id)
        timestamps_items = author_timestamps_item.xpath('./span[contains(concat(" ",normalize-space(@class)," ")," visible ")]')
        timestamps = Hash.new
        timestamps_items.each do |timestamp_item|
          case ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@title')
          when /\Aenviado\:\z/
            timestamp_sent = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::News::STATUS_TYPE['sent']] = timestamp_sent
          when /\Apublicado\:\z/
            timestamp_published = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::News::STATUS_TYPE['published']] = timestamp_published
          end
        end
        @timestamps = timestamps

        body_item = content_item.css('div.news-content')
        @body = ::Wagg::Utils::Functions.text_at_xpath(body_item, './text()')
      end

      def parse_statistics(shakeit_item, details_up_item)
        statistics = ::Wagg::Crawler::NewsStatistics.new(@snapshot_timestamp)

        clicks_item = shakeit_item.css('div.clics')
        statistics.num_clicks = ::Wagg::Utils::Functions.text_at_xpath(clicks_item, './span/text()').to_i

        details_items = details_up_item.css('div.news-details-data-up > span')
        details_items.each do |details_item|
          case ::Wagg::Utils::Functions.text_at_xpath(details_item, './@class')
          when /\Avotes-up\z/
            votes_up_item = details_item.css('span > strong')
            statistics.positive_votes = ::Wagg::Utils::Functions.text_at_xpath(votes_up_item, './span[@class="positive-vote-number"]/text()').to_i
          when /\Avotes-down\z/
            votes_down_item = details_item.css('span > strong')
            statistics.negative_votes = ::Wagg::Utils::Functions.text_at_xpath(votes_down_item, './span[@class="negative-vote-number"]/text()').to_i
          when /votes-anonymous/
            votes_anonymous_item = details_item.css('span > strong')
            statistics.anonymous_votes = ::Wagg::Utils::Functions.text_at_xpath(votes_anonymous_item, './span[@class="anonymous-vote-number"]/text()').to_i
          when /karma/
            karma_item = details_item.css('span.karma-value')
            statistics.karma = ::Wagg::Utils::Functions.text_at_xpath(karma_item, './span[@class="karma-number"]/text()').to_i
          when /sub\-name/
            sub_name_item = ::Wagg::Utils::Functions.text_at_xpath(details_item, './a/@href')
            sub_name_item_matched = sub_name_item.match(/\A\/m\/(?<sub_name>\w+)(?:\/\w+)?/)
            @category = sub_name_item_matched[:sub_name]
          end
        end

        num_comments_item = details_up_item.css('div.news-details-main > a')
        statistics.num_comments = ::Wagg::Utils::Functions.text_at_xpath(num_comments_item, './@data-comments-number').to_i

        @statistics = statistics
      end

      def parse_permalink(details_up_item)
        permalink_item = details_up_item.css('div.news-details-main > div > ul > li > button.share-link')
        permalink_uri = ::Wagg::Utils::Functions.text_at_xpath(permalink_item, './@data-clipboard-text')
        permalink_matched = permalink_uri.match(/\Ahttp\:\/\/menea\.me\/(?<permalink_id>[[:alnum:]]+)\z/)

        @permalink_id = permalink_matched[:permalink_id]
      end

      private :parse_id, :parse_id_extended, :parse_content, :parse_statistics, :parse_permalink
    end
  end
end