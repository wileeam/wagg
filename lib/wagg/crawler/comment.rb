# frozen_string_literal: true

module Wagg
  module Crawler
    # Since we take repeated snapshots of a news we need a versioning abstraction
    # which happens to be the statistics of the news
    class CommentStatistics
      attr_accessor :karma, :positive_votes, :negative_votes

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

      # @!attribute [r] votes
      #   @return [Array] the list of votes of the comment
      def votes
        if @votes.nil?
          @votes = ::Wagg::Crawler::CommentVotes.parse(@id)
        else
          @votes
        end
      end

      def initialize(raw_data, mode = 'rss', snapshot_timestamp = nil)
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        @raw_data = raw_data

        case mode
        when /\Arss\z/
          parse_rss(raw_data)
        when /\Ahtml\z/
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
          Comment.new(raw_data, mode, snapshot_timestamp)
        end
      end

      def get_data(uri, custom_retriever = nil)
        retriever = if custom_retriever.nil?
                      ::Wagg::Utils::Retriever.instance
                    else
                      custom_retriever
                    end

        retriever.get(uri, ::Wagg::Constants::Retriever::AGENT_TYPE['comment'], false)
      end

      def uri
        @link
      end

      def permalink
        format(format(::Wagg::Constants::Comment::MAIN_URL, id: @id))
      end

      def parse_votes
        @votes = ::Wagg::Crawler::CommentVotes.parse(@id) if !@id.nil? && @votes.nil?
      end

      # Private methods below

      def parse_html(raw_data)
        index_item = ::Wagg::Utils::Functions.text_at_xpath(raw_data, './div/@id')
        index_matched = index_item.match(/\Ac-(?<index>\d+)\z/)
        @index = index_matched[:index].to_i

        id_item = ::Wagg::Utils::Functions.text_at_xpath(raw_data, './div/@data-id')
        id_matched = id_item.match(/\Acomment-(?<id>\d+)\z/)
        @id = id_matched[:id]

        header_item = raw_data.css('div > div.comment-body > div.comment-header')
        author_name_item = header_item.css('a.username')
        author_name = ::Wagg::Utils::Functions.text_at_xpath(author_name_item, './@href')
        author_name_matched = author_name.match(%r{\A/user/(?<author>.+)/commented\z})
        author_name = author_name_matched[:author]
        author_id_item = header_item.at_css('img')
        author_id = ::Wagg::Crawler::Author.parse_id_from_img(author_id_item)
        @author = ::Wagg::Crawler::FixedAuthor.new(author_name, author_id, @snapshot_timestamp)

        timestamps = {}
        timestamps_items = header_item.css('span.ts')
        timestamps_items.each do |timestamp_item|
          case ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@title')
          when /\Acreado:\z/
            timestamp_created = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::Comment::STATUS_TYPE['created']] = timestamp_created
          when /\Aeditado:\z/
            timestamp_edited = ::Wagg::Utils::Functions.text_at_xpath(timestamp_item, './@data-ts').to_i
            timestamps[::Wagg::Constants::Comment::STATUS_TYPE['edited']] = timestamp_edited
          end
        end
        @timestamps = timestamps

        body_item = raw_data.css('div > div.comment-body > div.comment-text')
        body = body_item.inner_html.strip
        if body.match?(/\A.+(?<get_comment>href="javascript:get_votes\('get_comment\.php','comment','cid-#{@id}',0,#{@id}\)").+\z/)
          # TODO: RETRIEVE AGAIN
          @body = parse_hidden_body
        else
          @body = body
        end

        statistics = ::Wagg::Crawler::CommentStatistics.new(@snapshot_timestamp)
        footer_item = raw_data.css('div > div.comment-footer')
        votes_counter_item = footer_item.css(format('[id="vc-%{id}"]', id: @id))
        votes_counter = ::Wagg::Utils::Functions.text_at_xpath(votes_counter_item, './text()').to_i
        statistics.num_votes = votes_counter
        karma_item = footer_item.css(format('[id="vk-%{id}"]', id: @id))
        karma = ::Wagg::Utils::Functions.text_at_xpath(karma_item, './text()').to_i
        statistics.karma = karma
        @statistics = statistics
      end

      def parse_rss(raw_data)
        @id = raw_data.comment_id
        @author = ::Wagg::Crawler::FixedAuthor.new(raw_data.author)
        @body = raw_data.body
        @index = raw_data.index.to_i
        @timestamp = {}
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

      private :parse_html, :parse_rss, :parse_hidden_body
    end

    class ListComments
      attr_reader :id, :parser, :comments
      alias list comments
      def first
        @comments.first
      end

      def last
        @comments.last
      end

      def initialize(id, num_comments, mode = 'rss')
        @id = id
        @parser = mode
        parse(id, num_comments, mode)
      end

      def get_data(uri, custom_retriever = nil)
        retriever = if custom_retriever.nil?
                      ::Wagg::Utils::Retriever.instance
                    else
                      custom_retriever
                    end

        retriever.get(uri, ::Wagg::Constants::Retriever::AGENT_TYPE['comment'], false)
      end

      def as_hash
        keys = @comments.map(&:index)
        values = @comments

        Hash[keys.zip(values)]
      end

      # Private methods below

      def parse(id_news, num_comments, mode = 'rss')
        comments_list = []

        case mode
        when /\Arss\z/
          snapshot_timestamp = Time.now.utc

          comments_rss_uri = format(::Wagg::Constants::News::COMMENTS_RSS_URL, id: id_news)
          comments_xml = HTTParty.get(comments_rss_uri).body
          comments_rss = Feedjira.parse(comments_xml, parser: Feedjira::Parser::Wagg::CommentsList)
          comments_rss.entries.each do |comment_rss|
            comment = ::Wagg::Crawler::Comment.new(comment_rss, 'rss', snapshot_timestamp)
            # comments_hash[comment.index] = comment
            comments_list << comment
          end
        when /\Ahtml\z/
          num_pages, remaining_comments = num_comments.divmod(::Wagg::Constants::News::COMMENTS_URL_MAX_PAGE)
          num_pages += 1 if remaining_comments.positive?
          (1..num_pages).each do |page|
            snapshot_timestamp = Time.now.utc

            comments_html_uri = format(::Wagg::Constants::News::COMMENTS_URL, { id_extended: id_news, page: page })
            comments_html_raw_data = get_data(comments_html_uri)
            comments_html_list_items = comments_html_raw_data.css('div#newswrap > div#comments-top > ol > li')
            comments_html_list_items.each do |comment_item|
              comment = ::Wagg::Crawler::Comment.new(comment_item, 'html', snapshot_timestamp)
              # comments_hash[comment.index] = comment
              comments_list << comment
            end
          end

        else
          raise 'News\' comments parsing mode not supported yet unfortunately'
        end

        @comments = comments_list
      end

      private :parse
    end
  end
end
