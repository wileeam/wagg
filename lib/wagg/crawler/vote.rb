# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Vote #< ActiveRecord::Base
      attr_reader :author, :type, :weight, :timestamp, :item

      def initialize(author, weight, timestamp, item, type)
        @author = author
        @timestamp = timestamp
        @item = item
        @weight = weight
        @type = type
      end

      def to_s
        "%{ts} :: %{w}\t(%{a})" % {ts:Time.at(@timestamp), a:@author, w:@weight}
      end

      class << self

        def parse_news_votes(item)
          parse(item, Wagg::Utils::Constants::NEWS_VOTES_QUERY_URL, Wagg::Utils::Constants::VOTE_NEWS)
        end

        def parse_comment_votes(item)
          parse(item, Wagg::Utils::Constants::COMMENT_VOTES_QUERY_URL, Wagg::Utils::Constants::VOTE_COMMENT)
        end

        private
        def parse(item, url_template, type)
          Wagg::Utils::Retriever.instance.agent('vote', Wagg::Utils::Constants::RETRIEVAL_DELAY['vote'])

          votes = Array.new

          p = 1
          begin
            # Retrieve subpage with votes
            votes_subpage = Wagg::Utils::Retriever.instance.get(url_template % {id:item, page:p}, 'vote')
            # Find all votes: 'a' tags in DOM tree
            votes_partial_list = votes_subpage.search('.//div[contains(concat(" ", normalize-space(@class), " "), " voters-list ")]/div')
            # Process votes per sé (mainly parsing the 'title' attribute of the 'a' tag)
            for v in votes_partial_list
              vote_item = Wagg::Utils::Functions.str_at_xpath(v, './a/@title').match(Wagg::Utils::Constants::VOTE_RE)

              # Author's string name ONLY (no id...)
              # TODO: Should we retrieve the id from its personal section in the site? Not good idea: one query more per vote
              vote_author = vote_item.captures[0]
              #vote_author = Wagg::Crawler::Crawler.author(vote_item.captures[0])
              vote_timestamp = case vote_item.captures[1]
                                 # Comment regex: DD/MM-HH:MM:SS
                                 when /\A\d{1,2}\/\d{1,2}-\d{1,2}:\d{1,2}:\d{1,2}\z/
                                   DateTime.strptime(vote_item.captures[1],'%d/%m-%H:%M:%S').to_time.to_i
                                 # News regex: HH:MM TMZ
                                 when /\A\d{1,2}:\d{1,2}\s[A-Z]+\z/
                                   DateTime.strptime(vote_item.captures[1],'%H:%M %Z').to_time.to_i
                                 # News regex: DD-MM-YYYY HH:MM TMZ
                                 when /\A\d{1,2}-\d{1,2}-\d{4}\s\d{1,2}:\d{1,2}\s[A-Z]+\z/
                                   DateTime.strptime(vote_item.captures[1],'%d-%m-%Y %H:%M %Z').to_time.to_i
                               end
              if vote_item.captures[2].nil?
                vote_karma = Wagg::Utils::Constants::VOTE_NEWS_DOWNRATE[Wagg::Utils::Functions.str_at_xpath(v, './span/text()')]
              else
                vote_karma = vote_item.captures[2].to_i
              end
              vote_type = type

              vote = Vote.new(vote_author, vote_karma, vote_timestamp, item, vote_type)
              votes.unshift(vote)
            end
            p += 1
          end until votes_partial_list.empty?

          votes
        end
      end
    end
  end
end