# encoding: utf-8

require 'wagg/crawler/vote'

module Wagg
  module Crawler
    class Comment
      attr_reader :id, :author, :body, :timestamps
      attr_reader :news_url, :news_index
      attr_accessor :votes, :votes_count, :karma

      attr_reader :closed


      def initialize(id, author, body, timestamps, news_url, news_index)
        @id = id
        @author = author
        @body = body
        @timestamps = timestamps
        @news_url = news_url
        @news_index = news_index

        @karma = nil
        @votes_count = nil

        @votes = nil

        @closed = (timestamps['creation'] + Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME) >= timestamps['retrieval']
      end

      def votes(override_checks=FALSE)
        if @votes.nil?
          if (self.closed? || override_checks) && !@karma.nil? && !@votes_count.nil?
            @votes = Vote.parse_comment_votes(@id)
          end
        end
        @votes
      end

      def closed?
        @closed
      end

      def open?
        !@closed
      end

      def modified?
        @timestamps.has_key?('edition')
      end

      def votes?
        self.votes_available?
      end

      # TODO: Account for case when @votes_count == 0
      def votes_available?
        !@votes.nil? && @votes.size > 0
      end

      def votes_consistent?
        self.votes_available? && @votes_count == @votes.size
      end

      def position_in_news
        Wagg::Utils::Functions.str_at_xpath(@body, './a/strong/text()')[/(?<position>\d+)/].to_i
      end

      def to_s
        "COMMENT : %{id} - %{a}" % {id:@id, a:@author} +
            "\n" +
            "    %{news_index} - %{news_url}" % {news_index:@news_index, news_url:@news_url} +
            "\n" +
            "    %{ts}" % {ts:@timestamps} +
            "\n" +
            "    %{b}..." % {b:@body[0,20]} +
            "\n" +
            "    %{k} :: %{vc}" % {k:@karma, vc:@votes_count} +
            "\n" +
            "    (%{vc}) => %{v}" % {vc:(@votes.nil? ? 'EMPTY' : @votes.size), v:@votes}
      end

      class << self
        def parse(item, retrieval_timestamp=Time.now.to_i)
          # Parse comment's body data
          body_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-body ")]')
          comment_body = body_item.search('./child::node()').to_s.scrub.strip
          comment_id = Wagg::Utils::Functions.str_at_xpath(body_item, './@id')[/(?!c-)(?<id>\d+)/].to_i
          # Also available at unique id: //*[@id="cid-XXXXXXXX"]/a/@href
          # TODO: Use regex to remove last element in extraced href instead of these functions...
          comment_news_url = Wagg::Utils::Constants::SITE_URL + Wagg::Utils::Functions.str_at_xpath(body_item, './a/@href').split('/')[0...-1].join('/')
          comment_news_index = Wagg::Utils::Functions.str_at_xpath(item, './@id')[/(?!cid-)(?<id>\d+)/].to_i

          # Parse comment's authorship meta data
          meta_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-meta ")]')
          meta_info_item = meta_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comment-info ")]')

          comment_timestamps = parse_timestamps(meta_info_item)
          comment_timestamps["retrieval"] = retrieval_timestamp

          if meta_info_item.at_xpath('./a/@href').nil?
            comment_author = Wagg::Utils::Functions.str_at_xpath(meta_info_item, './strong/text()')
          else
            comment_author = Wagg::Utils::Functions.str_at_xpath(meta_info_item, './a/@href')[/\/user\/(?<author>.+)\/commented/,1]
          end

          # Parse comment's voting meta data
          ballot_item = meta_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comment-votes-info ")]')

          karma_item = Wagg::Utils::Functions.str_at_xpath(ballot_item, './span[@id="vk-%{id}"]/text()' % {id:comment_id})
          comment_karma = karma_item.nil? ? nil : karma_item.to_i

          vote_count_item = Wagg::Utils::Functions.str_at_xpath(ballot_item, './/span[@id="vc-%{id}"]/text()' % {id:comment_id})
          comment_votes_count = vote_count_item.nil? ? nil : vote_count_item.to_i

          comment = Wagg::Crawler::Comment.new(
              comment_id,
              comment_author,
              comment_body,
              comment_timestamps,
              comment_news_url,
              comment_news_index
          )

          # Fill the remaining details
          if comment.closed?
            comment.karma = comment_karma
            comment.votes_count = comment_votes_count
          end

          # Return the object containing the comment details
          comment
        end

        def parse_by_id(id)
          Wagg::Utils::Retriever.instance.agent('comment', Wagg.configuration.retrieval_delay['comment'])

          comment_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['comment']
          comment = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::COMMENT_URL % {comment:id} , 'comment')
          comments_list_item = comment.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
          # Note that at() is the same as search().first (which is what we want in fact)
          comment_item = comments_list_item.at('./div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/*[1][@id]')

          comment_object = parse(comment_item, comment_retrieval_timestamp)

          comment_object
        end

        #TODO: Complete and test
        def parse_by_index(news_url, comment_index)
          Wagg::Utils::Retriever.instance.agent('comment', Wagg.configuration.retrieval_delay['comment'])
          Wagg::Utils::Retriever.instance.agent('news', Wagg.configuration.retrieval_delay['news'])

          comment_news = News.parse(news_url)

          comment = Wagg::Utils::Retriever.instance.get(url, 'news')
          puts comment.search('//*[@id="newswrap"]')
          exit(0)
          comments_list_item = comment.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
          comment_item = comments_list_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]')
          #comment_item = comments_list_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/div[@id="c-%{index}"]' % {index:comment_index})
          comment_item.each do |c|
            puts c
          end
          exit(0)
          comment_object = parse(comment_item)

          comment_object
        end

        def parse_timestamps(meta_item)
          timestamp_items = meta_item.search('./span')

          comment_timestamps = Hash.new
          for t in timestamp_items
            case Wagg::Utils::Functions.str_at_xpath(t, './@title')
              when /\Acreado:/
                comment_timestamps["creation"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
              when /\Aeditado:/
                comment_timestamps["edition"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
            end
          end

          comment_timestamps
        end

        private :parse_timestamps

      end
    end
  end
end