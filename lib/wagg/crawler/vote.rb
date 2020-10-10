# encoding: UTF-8

require 'wagg/crawler/author'

module Wagg
  module Crawler
    class Vote
      attr_reader :type
      attr_reader :author
      attr_reader :sign
      attr_reader :weight
      attr_reader :timestamp

      def initialize(type, author_name, author_id, sign, weight, timestamp, snapshot_timestamp = nil)
        @type = type
        @author = ::Wagg::Crawler::FixedAuthor.new(author_name, author_id, snapshot_timestamp)
        @sign = sign
        @weight = weight
        @timestamp = timestamp
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
      end
    end

    class ListVotes
      attr_reader :id
      attr_reader :votes

      def num_votes
        @votes.length()
      end

      def positive_votes
        signs = @votes.map do |vote|
          vote.sign == ::Wagg::Constants::Vote::SIGN['positive'] ? 1 : 0
        end
        
        signs.sum
      end

      def negative_votes
        num_votes - positive_votes
      end

      def initialize(id, type = ::Wagg::Constants::Vote::TYPE['news'])
        @id = id
        @votes = parse(id, type)
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

      def parse(id, type = ::Wagg::Constants::Vote::TYPE['news'])
        min_page = 1
        max_page = min_page
        case type
        when /\A#{::Wagg::Constants::Vote::TYPE['news']}\z/
          votes_uri = format(::Wagg::Constants::News::VOTES_QUERY_URL, id: id, page: min_page)
        when /\A#{::Wagg::Constants::Vote::TYPE['comment']}\z/
          votes_uri = format(::Wagg::Constants::Comment::VOTES_QUERY_URL, id: id, page: min_page)
        end
        votes_list = []

        votes_raw_data = get_data(votes_uri)
        pages_item = votes_raw_data.css('div.pages > a')
        pages_item.each do |page_item|
          num_page = ::Wagg::Utils::Functions.text_at_xpath(page_item, './text()').to_i
          max_page = num_page if max_page < num_page
        end

        (min_page..max_page).each do |page|
          snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          case type
          when /\A#{::Wagg::Constants::Vote::TYPE['news']}\z/
            votes_uri = format(::Wagg::Constants::News::VOTES_QUERY_URL, id: id, page: page)
          when /\A#{::Wagg::Constants::Vote::TYPE['comment']}\z/
            votes_uri = format(::Wagg::Constants::Comment::VOTES_QUERY_URL, id: id, page: page)
          end
          votes_raw_data = get_data(votes_uri)

          #  div.voters-list > div > a
          votes_list_item = votes_raw_data.css('div.voters-list > div')
          votes_list_item.each do |vote_item|
            author_name_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/@href')
            author_name_matched = author_name_item.match(%r{\A/user/(?<author>.+)\z})
            author_name = author_name_matched[:author]
            author_id_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/img/@src')
            author_id_matched = author_id_item.match(%r{\Ahttps\:/{2}mnmstatic\.net/cache/\d{2}/[[:alnum:]]{2}/(?<id>\d+)\-(?<timestamp>\d+)\-\d{2}\.jpg\z})
            author_id = (author_id_matched[:id] unless author_id_matched.nil? || author_id_matched[:id].nil?)

            timestamp_weight_item = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './a/@title')
            case type
            when /\A#{::Wagg::Constants::Vote::TYPE['news']}\z/
              timestamp_weight_matched = timestamp_weight_item.match(::Wagg::Constants::Vote::NEWS_REGEX)
              vote_hash = timestamp_weight_matched.named_captures
              if vote_hash['datetime'].nil? && !vote_hash['time'].nil?
                now = DateTime.now.new_offset # Current datetime in UTC
                vote_date = DateTime.strptime(now.strftime('%d-%m-%Y') + ' ' + vote_hash['time'], '%d-%m-%Y %H:%M %Z')
              else
                vote_date = DateTime.strptime(vote_hash['datetime'], '%d-%m-%Y %H:%M %Z')
              end
              if vote_hash['weight']
                # Positive votes have a weight
                vote_sign = ::Wagg::Constants::Vote::NEWS_SIGN['positive']
                vote_weight = vote_hash['weight'].to_i
              else
                # Negative votes do NOT have a weight
                vote_weight_sign = ::Wagg::Utils::Functions.text_at_xpath(vote_item, './span/text()')
                vote_sign = ::Wagg::Constants::Vote::NEWS_SIGN['negative']
                vote_weight = ::Wagg::Constants::Vote::NEWS_NEGATIVE_WEIGHT[vote_weight_sign]
              end
            when /\A#{::Wagg::Constants::Vote::TYPE['comment']}\z/
              timestamp_weight_matched = timestamp_weight_item.match(::Wagg::Constants::Vote::COMMENT_REGEX)
              vote_hash = timestamp_weight_matched.named_captures
              now = DateTime.now.new_offset # Current datetime in UTC
              vote_date = DateTime.strptime(now.strftime('%Y') + '/' + vote_hash['datetime'] + ' ' + 'UTC', '%Y/%d/%m-%H:%M:%S %Z')
              vote_weight = vote_hash['weight'].to_i
              vote_sign = if vote_weight >= 0
                ::Wagg::Constants::Vote::COMMENT_SIGN['positive']
              else
                ::Wagg::Constants::Vote::COMMENT_SIGN['negative']
                          end
            end

            vote = ::Wagg::Crawler::Vote.new(type, author_name, author_id, vote_sign, vote_weight, vote_date, snapshot_timestamp)
            votes_list << vote
          end
        end

        votes_list
      end

    end
    
    class NewsVotes < ListVotes
      def initialize(id)
        super(id, ::Wagg::Constants::Vote::TYPE['news'])
      end

      class << self
        def parse(id)
          votes = NewsVotes.new(id)

          votes
        end
      end
    end

    class CommentVotes < ListVotes
      def initialize(id)
        super(id, ::Wagg::Constants::Vote::TYPE['comment'])
      end

      class << self
        def parse(id)
          votes = CommentVotes.new(id)

          votes
        end
      end
    end

  end
end