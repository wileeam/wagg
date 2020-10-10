# encoding: UTF-8

require 'wagg/crawler/author'

module Wagg
  module Crawler
    class Vote
      attr_reader :author
      attr_reader :type
      attr_reader :weight
      attr_reader :timestamp

      def initialize(author_name, author_id, type, weight, timestamp, snapshot_timestamp = nil)
        @author = ::Wagg::Crawler::FixedAuthor.new(author_name, author_id, snapshot_timestamp)
        @type = type
        @weight = weight
        @timestamp = timestamp
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
      end
    end

    class NewsVotes
      attr_reader :votes_list

      def initialize(votes = nil)
        if votes.instance_of?(Array)
          @votes_list = votes
        else
          @votes_list = nil
        end
      end

      class << self
        def parse(id)
          raise 'Not implemented yet'
        end
      end

      def get_data(uri, retriever = nil, retriever_type = ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['vote'])
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


      def add(vote)
        if vote.instance_of?(::Wagg::Crawler::Vote)
          votes_list << vote
        end
      end

      def add_many(votes)
        if votes.instance_of?(Array)
          @votes_list.concat(votes)
        end
      end
    end

    class CommentVotes

    end

  end
end