# encoding: utf-8

require 'wagg/crawler/vote'

module Wagg
  module Crawler
    class Comment
      attr_reader :id, :author, :body
      attr_reader :votes, :vote_count, :karma
      attr_reader :timestamps

      def initialize(id, body, timestamps, author, karma, votes, vote_count)
        @id = id
        @body = body
        @author = author
        @timestamps = timestamps
        @karma = karma
        @votes = votes
        @vote_count = vote_count
      end

      def sent_time
        @timestamps[0]
      end

      def modified_time
        if self.modified?
          @timestamps[1]
        else
          nil
        end
      end

      def modified?
        @timestamps.size > 1
      end

      # Light consistency check of vote data
      def voting_consistent?
        @votes.size == @vote_count
      end

      def position_in_news
        Wagg::Utils::Functions.str_at_xpath(@body, './a/strong/text()')[/(?<position>\d+)/].to_i
      end

      def to_s
        "%{id} :: %{a} - %{t}" % {id:@id, a:@author, t:@timestamps} +
            "\n" +
            "  %{k} :: %{vc}" % {k:@karma, vc:@vote_count} +
            "\n" +
            "  (%{vc}) => %{v}" % {vc:(@votes.nil? ? nil : @votes.size), v:@votes}
      end

      class << self
        def parse(item)
          # Parse comment's body data
          body_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-body ")]')
          comment_body = body_item.search('./child::node()')
          comment_id = Wagg::Utils::Functions.str_at_xpath(body_item, './@id')[/(?<id>\d+)/].to_i
          # Comment position in news can be extracted from the body (that is the object itself should do it and not in the parsing)
          # comment_news_position = Wagg::Utils::Functions.str_at_xpath(body_item, './a/strong/text()')[/(?<position>\d+)/].to_i

          # Parse comment's authorship meta data
          meta_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-info ")]')
          comment_timestamps = Array.new
          timestamp_items = meta_item.search('./span')
          for t in timestamp_items
            case Wagg::Utils::Functions.str_at_xpath(t, './@title')
              when /\Acreado:/
                comment_timestamps.unshift(Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i)
              when /\Aeditado:/
                comment_timestamps.push(Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i)
            end
          end
          comment_author = Wagg::Utils::Functions.str_at_xpath(meta_item, './a/@href')[/\/user\/(?<author>.+)\/commented/,1]

          # Parse comment's voting meta data
          ballot_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comment-votes-info ")]')
          karma_item = Wagg::Utils::Functions.str_at_xpath(ballot_item, './span[@id="vk-%{id}"]/text()' % {id:comment_id})
          comment_karma = karma_item.nil? ? -1 : karma_item.to_i
          vote_count_item = Wagg::Utils::Functions.str_at_xpath(ballot_item, './/span[@id="vc-%{id}"]/text()' % {id:comment_id})
          comment_vote_count = vote_count_item.nil? ? -1 : vote_count_item.to_i
          if (comment_karma == comment_vote_count) && (comment_karma == -1)
            comment_votes = nil
          else
            comment_votes = Wagg::Crawler::Vote.parse_comment_votes(comment_id)
          end

          Comment.new(comment_id, comment_body, comment_timestamps, comment_author, comment_karma, comment_votes, comment_vote_count)
        end

      end
    end
  end
end