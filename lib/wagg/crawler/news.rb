# encoding: utf-8

require 'wagg/crawler/comment'


module Wagg
  module Crawler
    class News
      # @!attribute [r] id
      #   @return [Fixnum] the unique id of the news
      attr_reader :id
      # @!attribute [r] title
      #   @return [String] the title of the news
      attr_reader :title
      # @!attribute [r] author
      #   @return [String] the author of the news
      attr_reader :author
      # @!attribute [r] description
      #   @return [String] the description of the news
      attr_reader :description
      # @!attribute [r] timestamps
      #   @return [Hash] the creation and publication (if available) timestamps of the news
      attr_reader :timestamps
      # @!attribute [r] category
      #   @return [String] the category of the news
      attr_reader :category
      # @!attribute [r] status
      #   @return [String] the status (published, queued, discarded) of the news
      attr_reader :status

      attr_accessor :karma, :votes_count, :clicks, :comments_count
      attr_accessor :tags

      def initialize(id, title, author, description, urls, timestamps, category, status)
        @id = id
        @title = title
        @author = author
        @description = description
        @urls = urls
        @timestamps = timestamps
        @category = category
        @status = status

        @karma = nil
        # TODO Include the following atribute in a future update method as the information changes over time.
        @clicks = nil
        @comments_count = nil
        @votes_count = nil

        @log = nil
        @comments = nil
        @votes = nil

        case @status
          when "discarded" #Wagg::Utils::Constants::NEWS_STATUS_TYPE["discarded"]
            @comments_closed = (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME['discarded']) <= @timestamps['retrieval']
            @votes_closed = (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) <= @timestamps['retrieval']
          when "queued" #Wagg::Utils::Constants::NEWS_STATUS_TYPE["queued"]
            @comments_closed = (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME['queued']) <= @timestamps['retrieval']
            @votes_closed = (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) <= @timestamps['retrieval']
          when "published" #Wagg::Utils::Constants::NEWS_STATUS_TYPE["published"]
            @comments_closed = (@timestamps['publication'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME['published']) <= @timestamps['retrieval']
            @votes_closed = (@timestamps['publication'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) <= @timestamps['retrieval']
          else
            # We have this for safety as it costs time (one new request to the server)
            @comments_closed = comments_contribution?
            @votes_closed = (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME) <= @timestamps['retrieval']
        end
      end

      def urls(normalize = TRUE)
        { 'internal' => self.url_internal(normalize), 'external' => @urls['external'] }
      end

      def url_internal(normalize = TRUE)
        normalize ?
            Wagg::Utils::Constants::NEWS_URL % {:url_id => URI(URI.escape(@urls['internal'])).path.split('/').last} :
            @urls['internal']
      end

      def url_external
        @urls['external']
      end

      def votes
        if @votes.nil? && self.votes_available?
          @votes = Vote.parse_news_votes(@id)
        end

        @votes
      end

      def comments
        if @comments.nil? && self.comments_available?
          @comments = parse_comments(Wagg.configuration.retrieval_comments_rss)
        end

        @comments
      end

      def log
        if @log.nil? && self.log_available?
          @log = parse_events_log
        end

        @log
      end

      def published?
        @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['published']
      end

      def queued?
        @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['queued']
      end

      def discarded?
        @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['discarded']
      end

      def commenting_closed?
        @comments_closed
      end

      def commenting_open?
        !@comments_closed
      end

      def voting_closed?
        @votes_closed
      end

      def voting_open?
        !@votes_closed
      end

      def comment(index)
        self.comments? ? self.comments[index] : nil
      end

      def comments?
        self.comments_available? && @comments_count > 0
      end

      def comments_available?
        TRUE # Comments are always available
      end

      def comments_consistent?
        self.comments? ? @comments_count == self.comments.size : FALSE
      end

      def votes?
        self.votes_available? && (@votes_count['positive'] + @votes_count['negative']) > 0
      end

      def votes_available?
        if @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['published']
          (@timestamps['publication'] <= @timestamps['retrieval']) &&
              (@timestamps['retrieval'] <= (@timestamps['publication'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME['published'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME))
        else # @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['queued'] || @status == Wagg::Utils::Constants::NEWS_STATUS_TYPE['discarded']
          (@timestamps['creation'] <= @timestamps['retrieval']) &&
              (@timestamps['retrieval'] <= (@timestamps['creation'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME['published'] + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME))
        end
      end

      def votes_consistent?
        self.votes? ? (@votes_count['positive'] + @votes_count['negative']) == self.votes.size : FALSE
      end

      def log_available?
        (@timestamps['creation'] <= @timestamps['retrieval']) &&
        (@timestamps['retrieval'] <= (@timestamps['creation'] + 2*Wagg::Utils::Constants::NEWS_VOTES_LIFETIME))
      end

      def to_s
        "NEWS : %{id} [%{ty}:%{vs}:%{cs}] - %{t} (%{cat})" % {id:@id, vs:self.voting_open? ? 'open' : 'closed', cs:self.commenting_open? ? 'open' : 'closed', ty:@status, t:@title, cat:@category} +
            "\n" +
            "    %{a} - %{ts}" % {a:@author, ts:@timestamps} +
            "\n" +
            "    %{d}..." % {d:@description[0,10]} +
            "\n" +
            "    %{u}" % {u:self.urls} +
            "\n" +
            "    %{k} :: %{vc} - %{c}" % {k:@karma, vc:@votes_count, c:@clicks} +
            "\n" +
            "    Tags: %{tg}" % {tg:(@tags.nil? ? 'EMPTY' : @tags)} +
            "\n" +
            "    Votes: %{v}" % {v:(@votes.nil? ? 'EMPTY' : @votes.size)} +
            "\n" +
            "    Comments: %{co}" % {co:(@comments.nil? ? 'EMPTY' : @comments.size)}
      end

      def parse_comments(rss=FALSE)
        if rss
          news_comments = parse_comments_rss
        else
            news_comments = parse_comments_html
        end

        news_comments
      end

      def parse_comments_rss
        news_comments = Hash.new

        comments_retrieval_timestamp = Time.now.to_i

        news_comments_rss =  Feedjira::Feed.fetch_and_parse(Wagg::Utils::Constants::NEWS_COMMENTS_RSS_URL % {id:@id})

        news_comments_rss.entries.each do |c|
          comment = Comment.parse_by_rss(c, comments_retrieval_timestamp)
          news_comments[comment.news_index] = comment
        end

        news_comments
      end

      def parse_comments_html
        news_comments = Hash.new

        comments_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['news']

        news_item = Wagg::Utils::Retriever.instance.get(@urls['internal'], 'news')
        news_comments_item = news_item.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')

        comments_item = news_comments_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/*[1][@id]')
        # Find out how many pages of comments there are (at least one, the news page)
        pages_item = news_comments_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " pages ")]/a')
        (pages_item.count != 0) ? pages_total = pages_item.count : pages_total = 1

        pages_counter = 1
        begin
          if pages_total > 1
            comments_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['news']
            comments_page = Wagg::Utils::Retriever.instance.get("%{url}/%{page}" % {url:@urls['internal'], page:pages_counter}, 'news')
            comments_item = comments_page.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/*[1][@id]')
          end

          comments_item.each do |c|
            begin
              comment = Comment.parse(c, comments_retrieval_timestamp)
              news_comments[comment.news_index] = comment
            rescue NoMethodError, TypeError => e
              # TODO: Do nothing? Next piece of code will take care of the missing comments?
            end
          end

          pages_counter += 1
        end while (pages_counter <= pages_total)

        # We need to make sure we have all comments because due to bad renderization on site's end some may be missing
        # If comments are missing, we revert to parsing them via RSS ()
        if news_comments.size < @comments_count
          news_comments_rss_retrieval_timestamp = Time.now.to_i
          news_comments_rss =  Feedjira::Feed.fetch_and_parse(Wagg::Utils::Constants::NEWS_COMMENTS_RSS_URL % {id:@id})

          # We try first to get the IDs of missing comments via RSS as it is just one request to the server
          news_missing_comments = Array.new
          news_comments_rss.entries.each do |missing_comment_rss|
            unless news_comments.map{ |index, c| c.news_index }.include?(missing_comment_rss.comment_news_index.to_i)
              news_missing_comments.push(missing_comment_rss)
            end
          end

          # Finally, we are expecting to have all missing comments IDs...
          news_missing_comments.each do |missing_comment_rss|
            begin
              missing_comment = Comment.parse_by_id(missing_comment_rss.comment_id.to_i)
            rescue NoMethodError, TypeError => e
              missing_comment = Comment.parse_by_rss(missing_comment_rss, news_comments_rss_retrieval_timestamp)
            end
            news_comments[missing_comment.news_index] = missing_comment
          end

          # If we haven't got all missing comments, then we have to do individual requests for the missing comments
          # For example, the RSS delivered from the server has a limit of 500 entries but there can be more comments
          if news_comments.size < @comments_count
            news_missing_comments_indexes = (1..@comments_count).to_a - news_comments.map{ |index, c| c.news_index }
            news_missing_comments_indexes.each do |missing_comment_index|
              comment_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['comment']
              news_item = Wagg::Utils::Retriever.instance.get("#{@urls['internal']}/c0#{missing_comment_index}#c-#{missing_comment_index}", 'comment')
              news_comment_item = news_item.search("//*[@id=\"c-#{missing_comment_index}\"]")
              begin
                missing_comment = Comment.parse(news_comment_item, comment_retrieval_timestamp)
                news_comments[missing_comment.news_index] = missing_comment
              rescue NoMethodError, TypeError => e
                # TODO: Nothing can be done at this stage as there are no other options to retrieve further comments
              end
            end
          end
        end

        news_comments
      end

      def parse_events_log
        news_log_events = Hash.new

        news_log_item = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::NEWS_LOG_QUERY_URL % {url:@urls['internal']}, 'news')
        log_items = news_log_item.search('//*[@id="voters-container"]/div')
        log_items.reverse_each do |log_event_item|
          log_event_timestamp_item = log_event_item.search('./div[1]/span')
          log_event_category_item = log_event_item.search('./div[2]')
          log_event_type_item = log_event_item.search('./div[3]/strong')
          log_event_user_item = log_event_item.search('./div[4]/a')

          news_log_event = Hash.new
          news_log_event["user"] = Wagg::Utils::Functions.str_at_xpath(log_event_user_item, './@href')[/\/user\/(?<author_name>.+)/,1]
          news_log_event["type"] = Wagg::Utils::Constants::NEWS_LOG_EVENT[Wagg::Utils::Functions.str_at_xpath(log_event_type_item, './text()')]
          news_log_event["category"] = Wagg::Utils::Functions.str_at_xpath(log_event_category_item, './text()').to_s

          news_log_events[Wagg::Utils::Functions.str_at_xpath(log_event_timestamp_item, './@data-ts').to_i] = news_log_event
        end

        news_log_events
      end

      def comments_contribution?(comments_item=nil)
        if comments_item.nil?
          news_item = Wagg::Utils::Retriever.instance.get(@urls['internal'], 'news')
          news_comments_item = news_item.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
        else
          news_comments_item = comments_item
        end
        comments_form_item = news_comments_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " commentform ")]')

        comments_form_item.at_xpath('./form').nil?
      end

      private :parse_comments, :parse_comments_rss, :parse_comments_html, :parse_events_log, :comments_contribution?


      class << self
        def parse(url)
          # We need to track when we make the retrieval and account for the configured delay in the 'pre_connect_hooks'
          # In theory we should consider the time when the request is executed by the server, but this is good enough
          news_retrieval_timestamp = Time.now.to_i + Wagg.configuration.retrieval_delay['news']

          news_item = Wagg::Utils::Retriever.instance.get(url, 'news').search('//*[@id="newswrap"]')
          news_summary_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')
          news_comments_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
          news_body_item = news_summary_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-body ")]')

          # Parse the summary of the news (same information we would get from the front page)
          # Reason for which the tags require the body_item again...
          news = parse_summary(news_summary_item, news_retrieval_timestamp)

          # Parse and add tags to the news summary and return it (as a full parsed news now)
          news.tags = parse_tags(news_body_item)

          # Return the object containing the full news (with votes, comments and tags details)
          news
        end

        def parse_summary(summary_item, retrieval_timestamp=Time.now.to_i)
          # Retrieve main news body DOM subtree
          body_item = summary_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-body ")]')

          # Parse title and unique id
          news_title = Wagg::Utils::Functions.str_at_xpath(body_item, './*[self::h1 or self::h2]/a/text()')
          news_id = Wagg::Utils::Functions.str_at_xpath(body_item, './*[self::h1 or self::h2]/a/@class')[/(?<id>\d+)/].to_i

          # Parse (brief) description as text
          # TODO: Possibly parse the full node instead (think of anything that is not text such as links,...)
          news_description = Wagg::Utils::Functions.str_at_xpath(body_item, './text()[normalize-space()]')

          # Parse URLs (internal and external)
          news_urls = parse_urls(body_item)

          # Retrieve main news meta-data DOM subtree
          meta_item = body_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-submitted ")]')

          # Parse sending and publishing timestamps
          news_timestamps = parse_timestamps(meta_item)
          news_timestamps["retrieval"] = retrieval_timestamp

          # Parse author of news post (NOT the author(s) of the news itself as we don't know/care about that)
          news_author = parse_author(meta_item)

          # Retrieve status of news
          news_status = parse_status(body_item)

          # TODO Since November 2016 there are two 'details_item' divs (one with an extra class 'main'). Find a solution
          # Retrieve details news meta-data DOM subtree
          details_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " news-details ")]')

          # Parse votes count: up-votes (registered and anonymous users) and down-votes (registered users)
          news_votes_count = parse_votes_count(details_item, news_id)

          # Parse comments'count
          news_comments_count = parse_comments_count(details_item)

          # Parse number of clicks
          clicks_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " clics ")]')
          news_clicks = Wagg::Utils::Functions.str_at_xpath(clicks_item, './text()')[/(?<id>\d+)/].to_i

          # Retrieve secondary details meta-data DOM subtree
          others_item = details_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " tool ")]')

          # Parse category
          news_category = Wagg::Utils::Functions.str_at_xpath(others_item, './a/@href')[/\/m\/(?<category>.+)/,1]

          # Parse karma (accumulative sum of users' votes, i.e., news weight)
          news_karma = Wagg::Utils::Functions.str_at_xpath(others_item, './span[@id="a-karma-%{id}"]/text()' % {id:news_id}).to_i

          # Create the news object (we only create it with data that won't 'change' over time)
          news = News.new(
              news_id,
              news_title,
              news_author,
              news_description,
              news_urls,
              news_timestamps,
              news_category,
              news_status
          )

          # Fill the remaining details
          news.clicks = news_clicks
          news.karma = news_karma
          news.votes_count = news_votes_count
          news.comments_count = news_comments_count

          # Return the object containing the summary of the news (no votes, no comments, no tags details)
          news
        end

        def parse_author(meta_item)
          author_item = meta_item.search('./a[contains(concat(" ", normalize-space(@class), " "), " tooltip ")]')

          news_author = Hash.new
          news_author["id"] = Wagg::Utils::Functions.str_at_xpath(author_item, './@class')[/(?<author_id>\d+)/].to_i
          news_author["name"] = Wagg::Utils::Functions.str_at_xpath(author_item, './@href')[/\/user\/(?<author_name>.+)/,1]

          news_author
        end

        def parse_urls(body_item)
          external_url_item = body_item
          internal_url_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " votes ")]')

          news_urls = Hash.new
          news_urls['external'] = Wagg::Utils::Functions.str_at_xpath(external_url_item, './*[self::h1 or self::h2]/a/@href')
          news_urls['internal'] = Wagg::Utils::Constants::SITE_URL + Wagg::Utils::Functions.str_at_xpath(internal_url_item, './a/@href')

          news_urls
        end

        def parse_timestamps(meta_item)
          timestamp_items = meta_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " ts ")]')

          news_timestamps = Hash.new
          for t in timestamp_items
            case Wagg::Utils::Functions.str_at_xpath(t, './@title')
              when /\Aenviado:/
                news_timestamps["creation"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
              when /\Apublicado:/
                news_timestamps["publication"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
            end
          end

          news_timestamps
        end

        def parse_votes_count(details_item, news_id)
          news_votes_count = Hash.new
          news_votes_count["positive"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span/span[@id="a-usu-%{id}"]/strong/text()' % {id:news_id}).to_i
          news_votes_count["negative"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span/span[@id="a-neg-%{id}"]/strong/text()' % {id:news_id}).to_i
          news_votes_count["anonymous"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span/span[@id="a-ano-%{id}"]/strong/text()' % {id:news_id}).to_i

          news_votes_count
        end

        def parse_comments_count(details_item)
          Wagg::Utils::Functions.str_at_xpath(details_item, './/span[contains(concat(" ", normalize-space(@class), " "), " counter ")]/text()').to_i
        end

        def parse_tags(body_item)
          tags_item = body_item.search('.//span[contains(concat(" ", normalize-space(@class), " "), " news-tags ")]/a')

          news_tags = Array.new
          for t in tags_item
            unless Wagg::Utils::Functions.str_at_xpath(t, './text()').nil?
              unless Wagg::Utils::Functions.str_at_xpath(t, './text()').empty?
                news_tags.push(Wagg::Utils::Functions.str_at_xpath(t, './text()'))
              end
            end

          end

          news_tags
        end

        def parse_status(body_item)
          status_main_item = body_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-shakeit ")]')
          status_item = Wagg::Utils::Functions.str_at_xpath(status_main_item, './@class').split

          if status_item.include?(Wagg::Utils::Constants::NEWS_STATUS_TYPE["queued"])
            news_status = "queued"
          elsif status_item.include?(Wagg::Utils::Constants::NEWS_STATUS_TYPE["published"])
            news_status = "published"
          elsif status_item.include?(Wagg::Utils::Constants::NEWS_STATUS_TYPE["discarded"])
            news_status = "discarded"
          else
            raise error
          end

          news_status
        end

        private :parse_author, :parse_urls, :parse_timestamps, :parse_votes_count, :parse_comments_count, :parse_tags, :parse_status
      end

    end
  end
end