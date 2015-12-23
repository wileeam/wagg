# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Vote
      attr_reader :author, :rate, :weight, :timestamp, :item, :type

      def initialize(author, weight, rate, timestamp, item, type)
        @author = author
        @timestamp = timestamp
        @item = item
        @weight = weight
        @rate = rate
        @type = type
      end

      def to_s
        "VOTE : %{ts} (%{t}) :: %{w} (%{r}) - %{a}" % {ts:Time.at(@timestamp), t:@type, a:@author, w:@weight, r:@rate}
      end

      class << self
        def parse_news_votes(news_id)
          parse(news_id, Wagg::Utils::Constants::NEWS_VOTES_QUERY_URL, Wagg::Utils::Constants::VOTE_NEWS)
        end

        def parse_comment_votes(comment_id)
          parse(comment_id, Wagg::Utils::Constants::COMMENT_VOTES_QUERY_URL, Wagg::Utils::Constants::VOTE_COMMENT)
        end

        def parse(item, url_template, type)
          votes = Array.new

          p = 1
          begin
            # Retrieve subpage with votes
            votes_subpage = Wagg::Utils::Retriever.instance.get(url_template % {id:item, page:p}, 'vote')

            votes_retrieval_timestamp = Time.now.utc + Wagg.configuration.retrieval_delay['vote']

            # Find all votes: 'a' tags in DOM tree
            votes_partial_list = votes_subpage.search('.//div[contains(concat(" ", normalize-space(@class), " "), " voters-list ")]/div')

            # Process votes per sé (mainly parsing the 'title' attribute of the 'a' tag)
            for v in votes_partial_list
              vote_item = Wagg::Utils::Functions.str_at_xpath(v, './a/@title').match(Wagg::Utils::Constants::VOTE_RE)

              # Author's string name ONLY (no id...)
              # TODO: Should we retrieve the id from its personal section in the site? Not good idea: one query more per vote
              vote_author = vote_item.captures[0]
              vote_timestamp = case vote_item.captures[1]
                                 # Comment regex: DD/MM-HH:MM:SS
                                 # No TMZ provided, enforced UTC like the rest of the site
                                 # Checked that TMZ is UTC
                                 when /\A\d{1,2}\/\d{1,2}-\d{1,2}:\d{1,2}:\d{1,2}\z/
                                   DateTime.strptime(vote_item.captures[1] + ' UTC','%d/%m-%H:%M:%S %Z').to_time.to_i
                                 # News regex: HH:MM TMZ
                                 # DD/MM have to be inferred
                                 when /\A\d{1,2}:\d{1,2}\s[A-Z]+\z/
                                   #DateTime.strptime(vote_item.captures[1],'%H:%M %Z').to_time.to_i
                                   # Check if we are on the same (===) day
                                   if votes_retrieval_timestamp.to_date === (votes_retrieval_timestamp - (20*60*60)).to_date
                                     vote_date_string =
                                         votes_retrieval_timestamp.day.to_s +
                                         '-' +
                                         votes_retrieval_timestamp.month.to_s +
                                         '-' +
                                         votes_retrieval_timestamp.year.to_s
                                   elsif vote_item.captures[1][/(\d{2}:\d{2})/] <= votes_retrieval_timestamp.strftime('%H:%M')
                                     vote_date_string =
                                         votes_retrieval_timestamp.day.to_s +
                                         '-' +
                                         votes_retrieval_timestamp.month.to_s +
                                         '-' +
                                         votes_retrieval_timestamp.year.to_s
                                   else
                                     votes_retrieval_timestamp_adjusted = votes_retrieval_timestamp - 24*60*60
                                     vote_date_string =
                                         votes_retrieval_timestamp_adjusted.day.to_s +
                                         '-' +
                                         votes_retrieval_timestamp_adjusted.month.to_s +
                                         '-' +
                                         votes_retrieval_timestamp_adjusted.year.to_s
                                   end
                                   vote_adjusted_timestamp = vote_date_string + ' ' + vote_item.captures[1]
                                   DateTime.strptime(vote_adjusted_timestamp, '%d-%m-%Y %H:%M %Z').to_time.to_i
                                 # News regex: DD-MM-YYYY HH:MM TMZ
                                 when /\A\d{1,2}-\d{1,2}-\d{4}\s\d{1,2}:\d{1,2}\s[A-Z]+\z/
                                   DateTime.strptime(vote_item.captures[1], '%d-%m-%Y %H:%M %Z').to_time.to_i
                               end
              if vote_item.captures[2].nil?
                # Vote is negative so we take the weight of the vote's author
                # TODO Compare vote_timestamp with current time, if differ more than 24 hours, karma is not accurate
                vote_karma = -1 * Author.parse(vote_author).karma.round
                vote_rate = Wagg::Utils::Constants::VOTE_NEWS_DOWNRATE[Wagg::Utils::Functions.str_at_xpath(v, './span/text()')]
              else
                vote_karma = vote_item.captures[2].to_i

                # By default we assume it is a positive vote for news, if not, we check for the weight
                vote_rate = Wagg::Utils::Constants::VOTE_NEWS_UPRATE
                if type == Wagg::Utils::Constants::VOTE_COMMENT
                  if vote_karma > 0
                    vote_rate = Wagg::Utils::Constants::VOTE_COMMENT_UPRATE
                  else
                    vote_rate = Wagg::Utils::Constants::VOTE_COMMENT_DOWNRATE
                  end
                end

              end
              vote_type = type

              vote = Vote.new(vote_author, vote_karma, vote_rate, vote_timestamp, item, vote_type)
              votes.unshift(vote)
            end
            p += 1
          end until votes_partial_list.empty?

          votes
        end

        private :parse
      end
    end
  end
end