# encoding: UTF-8

module Wagg
  module Crawler
    class NewsSummary
      # @!attribute [r] id
      #   @return [Integer] the unique id of the news
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

      def snapshot_timestamp
        @snapshot_timestamp
      end

      def initialize(raw_data, snapshot_timestamp = nil, json_data = nil)
        if json_data.nil?
          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          @raw_data = raw_data

          # div.news-body
          id_item = raw_data.css('div.news-body')
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
        else
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
        end
      end

      class << self
        def parse(raw_data, snapshot_timestamp)
          news_summary = NewsSummary.new(raw_data, snapshot_timestamp)

          news_summary
        end
      end

      # Clarifies whether the news is an article or not
      #
      # @return [Boolean] returns whether category is articles or not
      def article?
        !!(@link.equal?(@link) || @category.match?(::Wagg::Constants::News::CATEGORY_TYPE['articles']))
      end

      def from_json(string)
        os_object = JSON.parse(string, object_class: OpenStruct)

        # Some validation that we have the right object
        if os_object.type == self.name.split('::').last
          data = os_object.data

          snapshot_timestamp = Time.at(os_object.timestamp).utc

          NewsSummary.new(nil, snapshot_timestamp, data)
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
        id = ::Wagg::Utils::Functions.text_at_xpath(id_item, './@data-link-id')
        @id = id.to_i
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
        @title = title
        # News' link
        link = ::Wagg::Utils::Functions.text_at_xpath(title_link_item, './a/@href')
        @link = link

        author_timestamps_item = content_item.css('div.news-submitted')
        # Author's id
        # We don't use ::Wagg::Crawler::Author.get_id() because './a/@class' contains the author's id directly
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
            timestamps[::Wagg::Constants::News::STATUS_TYPE['sent']] = Time.at(timestamp_sent).utc.to_datetime
          when /\Apublicado\:\z/
            timestamp_published = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::News::STATUS_TYPE['published']] = Time.at(timestamp_published).utc.to_datetime
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
              timestamps: ::Wagg::Utils::Functions.hash_str_datetime_to_json(@ranking, true),
              category: @category,
              statistics: @statistics.to_json
            }
        }
      end

      def to_json(*options)
        as_json(*options).to_json(*options)
      end

    end
  end
end