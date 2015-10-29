# encoding: utf-8

require 'wagg/crawler/comment'


module Wagg
  module Crawler
    class News
      attr_reader :id, :title, :author, :description, :timestamps, :urls, :category
      attr_accessor :karma, :votes_count, :clicks, :comments_count
      attr_accessor :tags

      attr_reader :closed


      def initialize(id, title, author, description, urls, timestamps, category)
        @id = id
        @title = title
        @author = author
        @description = description
        @urls = urls
        @timestamps = timestamps
        @category = category

        @karma = nil
        @clicks = nil
        @comments_count = nil
        @votes_count = nil

        @comments = nil
        @votes = nil

        @closed = (timestamps['publication'] + Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME) < timestamps['retrieval']
      end

      def votes(override_checks=FALSE)
        if @votes.nil?
          if self.closed? || override_checks
            @votes = Vote.parse_news_votes(@id)
          end
        end
        @votes
      end

      def comments(override_checks=FALSE)
        if @comments.nil?
          if self.closed? || override_checks
            @comments = parse_comments
          end
        end
        @comments
      end

      def closed?
        @closed
      end

      def open?
        !@closed
      end

      def comment(index)
        self.comments_available? ? @comments[index] : nil
      end

      def comments?
        self.comments_available?
      end

      def comments_available?
        !@comments.nil? && @comments.size > 0
      end

      def comments_consistent?
        self.comments_available? && @comments_count == @comments.size
      end

      def votes?
        self.votes_available?
      end

      def votes_available?
        !@votes.nil? && @votes.size > 0
      end

      def votes_consistent?
        self.votes_available? && @votes_count == @votes.size
      end

      def to_s
        "NEWS : %{id} [%{s}] - %{t} (%{cat})" % {id:@id, s:self.open? ? 'open' : 'closed', t:@title, cat:@category} +
            "\n" +
            "    %{a} - %{ts}" % {a:@author, ts:@timestamps} +
            "\n" +
            "    %{d}..." % {d:@description[0,10]} +
            "\n" +
            "    %{u}" % {u:@urls} +
            "\n" +
            "    %{k} :: %{vc} - %{c}" % {k:@karma, vc:@votes_count, c:@clicks} +
            "\n" +
            "    Tags: %{tg}" % {tg:(@tags.nil? ? 'EMPTY' : @tags)} +
            "\n" +
            "    Votes: %{v}" % {v:(@votes.nil? ? 'EMPTY' : @votes.size)} +
            "\n" +
            "    Comments: %{co}" % {co:(@comments.nil? ? 'EMPTY' : @comments.size)}
      end

      def parse_comments
        Wagg::Utils::Retriever.instance.agent('news', Wagg.configuration.retrieval_delay['news'])

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
            comment = Comment.parse(c, comments_retrieval_timestamp)
            news_comments[comment.news_index] = comment
          end

          pages_counter += 1
        end while (pages_counter <= pages_total)

        news_comments
      end

      private :parse_comments


      class << self
        def parse(url)
          Wagg::Utils::Retriever.instance.agent('news', Wagg.configuration.retrieval_delay['news'])

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

          # Parse author of news post (NOT the author(s) of the news itself as we don't know/care)
          news_author = parse_author(meta_item)

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
              news_category
          )

          # Fill the remaining details
          if news.closed?
            news.clicks = news_clicks
            news.karma = news_karma
            news.comments_count = news_comments_count
            news.votes_count = news_votes_count
          end

          # Return the object containing the summary of the news (no votes, comments, tags details)
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
          news_votes_count["positive"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span[@id="a-usu-%{id}"]/text()' % {id:news_id}).to_i
          news_votes_count["negative"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span[@id="a-neg-%{id}"]/text()' % {id:news_id}).to_i
          news_votes_count["anonymous"] = Wagg::Utils::Functions.str_at_xpath(details_item, './/span[@id="a-ano-%{id}"]/text()' % {id:news_id}).to_i

          news_votes_count
        end

        def parse_comments_count(details_item)
          news_comments_count = Wagg::Utils::Functions.str_at_xpath(details_item, './span/a/span[contains(concat(" ", normalize-space(@class), " "), " counter ")]/text()').to_i

          news_comments_count
        end

        def parse_tags(body_item)
          tags_item = body_item.search('.//span[contains(concat(" ", normalize-space(@class), " "), " news-tags ")]/a')

          news_tags = Array.new
          for t in tags_item
            unless Wagg::Utils::Functions.str_at_xpath(t, './text()').nil?
              news_tags.push(Wagg::Utils::Functions.str_at_xpath(t, './text()'))
            end

          end

          news_tags
        end

        private :parse_author, :parse_urls, :parse_timestamps, :parse_votes_count, :parse_comments_count, :parse_tags
      end

    end
  end
end