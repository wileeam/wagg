# encoding: UTF-8

module Wagg
  module Crawler
    # Since we take repeated snapshots of a news we need a versioning abstraction
    # which happens to be the statistics of the news
    class CommentStatistics
      attr_accessor :karma
      attr_accessor :positive_votes
      attr_accessor :negative_votes

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

    class Comment
      # @!attribute [r] id
      #   @return [Fixnum] the unique id of the comment
      attr_reader :id
      # @!attribute [r] author
      #   @return [FixedAuthor] the author of the comment
      attr_reader :author
      # @!attribute [r] body
      #   @return [String] the body of the comment
      attr_reader :body
      # @!attribute [r] index
      #   @return [Fixnum] the index of the comment in the news
      attr_reader :index
      # @!attribute [r] timestamps
      #   @return [Hash] the status timestamp of the comment
      attr_reader :timestamps
      # @!attribute [r] statistics
      #   @return [CommentStatistics] the statistics of the comment
      attr_reader :statistics


      def initialize(raw_data, mode='rss', snapshot_timestamp = nil)
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        @raw_data = raw_data

        case mode
        when 'rss'
          parse_rss(raw_data)
        when 'html'
          parse_html(raw_data)
        else
          raise 'Comment parse mode not supported unfortunately.'
        end
      end

      def permalink_id
        @id
      end

      class << self
        def parse(raw_data, mode, snapshot_timestamp)
          comment = Comment.new(raw_data, mode, snapshot_timestamp)

          comment
        end
      end

      def get_data(uri, retriever = nil, retriever_type = ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['comment'])
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
        @link
      end

      def permalink
        format(::Wagg::Constants::Comment::MAIN_URL % {id:@id})
      end

      def parse_html(raw_data)
        index_item = ::Wagg::Utils::Functions.text_at_xpath(raw_data, './div/@id')
        index_matched = index_item.match(%r{\Ac\-(?<index>\d+)\z})
        @index = index_matched[:index].to_i

        id_item = ::Wagg::Utils::Functions.text_at_xpath(raw_data, './div/@data-id')
        id_matched = id_item.match(%r{\Acomment\-(?<id>\d+)\z})
        @id = id_matched[:id]

        header_item = raw_data.css('div > div.comment-body > div.comment-header')
        author_name_item = header_item.css('a.username')
        author_name = ::Wagg::Utils::Functions.text_at_xpath(author_name_item, './@href')
        author_matched = author_name.match(%r{\A\/user\/(?<author>.+)\/commented\z})
        author = author_matched[:author]
        @author = ::Wagg::Crawler::FixedAuthor.new(author)

        timestamps = Hash.new
        timestamps_items = header_item.css('span.ts')
        timestamps_items.each do |timestamp_item|
          case ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@title')
          when /\Acreado\:\z/
            timestamp_created = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::Comment::STATUS_TYPE['created']] = timestamp_created
          when /\Aeditado\:\z/
            timestamp_edited = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::Comment::STATUS_TYPE['edited']] = timestamp_edited
          end
        end
        @timestamps = timestamps

        body_item = raw_data.css('div > div.comment-body > div.comment-text')
        body = body_item.inner_html.strip
        if body.match?(%r{\A.+(?<get_comment>href\=\"javascript\:get\_votes\(\'get\_comment\.php\'\,\'comment\'\,\'cid\-#{@id}\'\,0\,#{@id}\)\").+\z})
          # TODO RETRIEVE AGAIN
          @body = parse_hidden_body
        else
          @body = body
        end

        statistics = ::Wagg::Crawler::CommentStatistics.new(@snapshot_timestamp)
        footer_item = raw_data.css('div > div.comment-footer')
        votes_counter_item = footer_item.css('[id="vc-%{id}"]' % {id:@id})
        votes_counter = ::Wagg::Utils::Functions.text_at_xpath(votes_counter_item, './text()').to_i
        statistics.num_votes = votes_counter
        karma_item = footer_item.css('[id="vk-%{id}"]' % {id:@id})
        karma = ::Wagg::Utils::Functions.text_at_xpath(karma_item, './text()').to_i
        statistics.karma = karma
        @statistics = statistics
      end

      def parse_rss(raw_data)
        @id = raw_data.comment_id
        @author = ::Wagg::Crawler::FixedAuthor.new(raw_data.author)
        @body = raw_data.body
        @index = raw_data.index.to_i
        @timestamp = Hash.new
        # @timestamp['creation'] = DateTime.strptime(raw_data.published, '%a, %d %b %Y %H:%M:%S %z')
        @timestamp['creation'] = raw_data.published.to_i
        statistics = ::Wagg::Crawler::CommentStatistics.new(@snapshot_timestamp)
        statistics.karma = raw_data.karma.to_i
        statistics.num_votes = raw_data.num_votes.to_i
        @statistics = statistics
      end

      def parse_hidden_body
        raw_data = get_data(format(::Wagg::Constants::Comment::HIDDEN_URL, id: @id))
        body_item = raw_data.css('body')

        body_item.inner_html.strip
      end

      private :parse_hidden_body
    end
  end
end