# encoding: utf-8

require 'wagg/crawler/vote'

module Wagg
  module Crawler
    class Comment
      attr_reader :id, :author, :news_index, :body
      attr_reader :votes, :vote_count, :karma
      attr_reader :timestamps

      def initialize(id, news_index, body, timestamps, author, karma, votes, vote_count)
        @id = id
        @news_index = news_index
        @body = body
        @author = author
        @timestamps = timestamps
        @karma = karma
        @votes = votes
        @vote_count = vote_count
      end

      def modified?
        @timestamps.has_key?('edition')
      end

      # Light consistency check of vote data
      def voting_consistent?
        @votes.size == @vote_count
      end

      def position_in_news
        Wagg::Utils::Functions.str_at_xpath(@body, './a/strong/text()')[/(?<position>\d+)/].to_i
      end

      def votes_available?(news_timestamps)
        (Time.now.to_i - news_timestamps['publication']) <= (Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) \
        and \
        (Time.now.to_i - news_timestamps['publication']) > Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME \
        and \
        (Time.now.to_i - @timestamps['creation'] > Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME) \
        and \
        not self.votes.nil?
      end

      def to_s
        "COMMENT : %{id} (%{news_index}) - %{a}" % {id:@id, news_index:@news_index, a:@author} +
            "\n" +
            "    %{ts}" % {ts:@timestamps} +
            "\n" +
            "    %{b}..." % {b:@body[0,20]} +
            "\n" +
            "    %{k} :: %{vc}" % {k:@karma, vc:@vote_count} +
            "\n" +
            "    (%{vc}) => %{v}" % {vc:(@votes.nil? ? 'EMPTY' : @votes.size), v:@votes}
      end

      class << self
        def parse(item, news_timestamps, with_votes=FALSE)
          # Parse comment's body data
          body_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-body ")]')
          comment_body = body_item.search('./child::node()').to_s.scrub.strip
          comment_id = Wagg::Utils::Functions.str_at_xpath(body_item, './@id')[/(?!c-)(?<id>\d+)/].to_i
          comment_news_index = Wagg::Utils::Functions.str_at_xpath(item, './@id')[/(?!cid-)(?<id>\d+)/].to_i

          # Parse comment's authorship meta data
          meta_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-meta ")]')
          meta_info_item = meta_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comment-info ")]')

          comment_timestamps = Comment.parse_timestamps(meta_info_item)

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
          comment_vote_count = vote_count_item.nil? ? nil : vote_count_item.to_i

          comment_votes = nil
          if with_votes and !comment_karma.nil? and !comment_vote_count.nil? and (Time.now.to_i - news_timestamps['publication']) <= (Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) and ((Time.now.to_i - comment_timestamps['creation']) > Wagg::Utils::Constants::COMMENT_VOTES_LIFETIME)
            comment_votes = Wagg::Crawler::Vote.parse_comment_votes(comment_id)
          end

          comment = Wagg::Crawler::Comment.new(
              comment_id,
              comment_news_index,
              comment_body,
              comment_timestamps,
              comment_author,
              comment_karma,
              comment_votes,
              comment_vote_count
          )

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

      end
    end
  end
end