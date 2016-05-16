# encoding: utf-8

require 'wagg/crawler/vote'

module Wagg
  module Crawler
    class Comment
      attr_reader :id, :author, :timestamps, :body
      attr_reader :news_index #,:news_url
      attr_accessor :votes_count, :karma

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

        @votes_closed = (@timestamps['creation'] + Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME) <= @timestamps['retrieval']
      end

      def news_url(normalize = TRUE)
        normalize ? Wagg::Utils::Constants::NEWS_URL % {:url_id => URI(URI.escape(@news_url)).path.split('/').last} : @news_url
      end

      def votes
        if @votes.nil? && self.votes_available?
          # TODO Revise the karma.nil and votes_count.nil case
          #if !@karma.nil? && !@votes_count.nil?
            @votes = Vote.parse_comment_votes(@id)
          #end
        end

        @votes
      end

      def voting_closed?
        @votes_closed
      end

      def voting_open?
        !@votes_closed
      end

      def modified?
        @timestamps.has_key?('edition') && !@timestamps['edition'].nil? && @timestamps['edition'] > 0
      end

      def votes?
        # TODO Revise the karma.nil and votes_count.nil case
        # votes_count can be nil but still data can be accessed via backend
        #self.votes_available? && @votes.size > 0
        self.votes_available? && @votes_count > 0
      end

      def votes_available?
        (@timestamps['creation'] <= @timestamps['retrieval']) &&
            (@timestamps['retrieval'] <= (@timestamps['creation'] + Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME + Wagg::Utils::Constants::COMMENT_CONTRIBUTION_LIFETIME))
      end

      def votes_consistent?
        self.votes? ? @votes_count == self.votes.size : FALSE
      end

      def parent_index
        referred_comments_list = @body.search('.//a[contains(concat(" ", normalize-space(@class), " "), " tooltip ")]')
        @body.each { |x| puts x.class }
        puts referred_comments_list
        #referred_comments_list = @body.search('//a[matches(@class, "tooltip c:%{cid}-\d+"]' % {cid: @id})
        parent_comment_item = referred_comments_list.first
        parent_comment_index = Wagg::Utils::Functions.str_at_xpath(@body, './a/text()').to_i

        parent_comment_index
      end

      def position_in_news
        Wagg::Utils::Functions.str_at_xpath(@body, './a/strong/text()')[/(?<position>\d+)/].to_i
      end

      def to_s
        "COMMENT : %{id} - %{a}" % {id:@id, a:@author} +
            "\n" +
            "    %{news_index} - %{news_url}" % {news_index:@news_index, news_url:(Wagg::Utils::Constants::NEWS_URL % {:url_id => self.news_url})} +
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

          comment_id = Wagg::Utils::Functions.str_at_xpath(body_item, './@id')[/(?!c-)(?<id>\d+)/].to_i
          # Also available at unique id: //*[@id="cid-XXXXXXXX"]/a/@href
          # TODO: Use regex to remove last element in extraced href instead of these functions...
          news_url_item = Wagg::Utils::Functions.str_at_xpath(body_item, './a/@href').split('/')[0...-1].join('/')
          comment_news_url = Wagg::Utils::Constants::SITE_URL + news_url_item
          comment_news_index = Wagg::Utils::Functions.str_at_xpath(item, './@id')[/(?!cid-)(?<id>\d+)/].to_i

          #comment_body = body_item.inner_html.strip.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          body_slice_string = "<a href=\"#{news_url_item}/c0#{comment_news_index}#c-#{comment_news_index}\" rel=\"nofollow\"><strong>##{comment_news_index}</strong></a>"
          # Using 'gsub(/[[:space:]]/, ' ')' to normalize spaces instead of '/text()[normalize-space()]'
          comment_body = body_item.inner_html.scrub.tap{|s| s.slice!(body_slice_string)}.gsub(/[[:space:]]/, ' ').strip

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
          comment.karma = comment_karma
          comment.votes_count = comment_votes_count

          # Return the object containing the comment details
          comment
        end

        def parse_by_id(id)
          comment_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['comment']
          comment = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::COMMENT_URL % {comment:id} , 'comment')
          comments_list_item = comment.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
          # Note that at() is the same as search().first (which is what we want in fact)
          comment_item = comments_list_item.at('./div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/*[1][@id]')

          comment_object = parse(comment_item, comment_retrieval_timestamp)

          comment_object
        end

        def parse_by_rss(item, retrieval_timestamp=Time.now.to_i)

          comment_id = item.comment_id.to_i
          comment_author = item.comment_author_name
          comment_body = item.summary
          comment_timestamps = Hash.new
          comment_timestamps['creation'] = item.published.to_i
          comment_timestamps['retrieval'] = retrieval_timestamp
          comment_news_url = item.comment_news_url_internal
          comment_news_index = item.comment_news_index.to_i

          comment = Wagg::Crawler::Comment.new(
              comment_id,
              comment_author,
              comment_body,
              comment_timestamps,
              comment_news_url,
              comment_news_index
          )

          # Fill the remaining details
          comment.karma = item.comment_karma.to_i
          comment.votes_count = item.comment_votes_count.to_i

          # Return the object containing the comment details
          comment
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