# encoding: utf-8

require 'wagg/crawler/comment'


module Wagg
  module Crawler
    class News
      attr_accessor :id, :title, :author, :description, :category, :urls, :timestamps
      attr_accessor :karma, :votes_count, :clicks
      attr_reader   :votes
      # TODO: Remove this attribute, not reliable if news is still open for commenting
      attr_accessor :comments_count
      attr_accessor :tags
      attr_accessor :comments

      # TODO: Decide whether to store the full raw news in the news after processing or not
      attr_reader :raw

      def initialize(id, title, author, description, urls, timestamps, category)
        @id = id
        @title = title
        @author = author
        @description = description
        @urls = urls
        @timestamps = timestamps
        @category = category
      end

      def closed?
        (Time.now.to_i - @timestamps['publication']) > Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME
      end

      #def closed?
      #  closed_item = @raw.search('.//div[contains(concat(" ", normalize-space(@class), " "), " menealo ")]')
      #  span_object = closed_item.search('./span')
      #  (!span_object.nil? && Wagg::Utils::Functions.str_at_xpath(span_object, './text()') == 'menealo') ? TRUE : FALSE
      #end

      def open?
        !self.closed?
      end

      #private method
      def votes_available?
        self.closed? and (Time.now.to_i - @timestamps['publication']) <= (Wagg::Utils::Constants::NEWS_CONTRIBUTION_LIFETIME + Wagg::Utils::Constants::NEWS_VOTES_LIFETIME)
      end

      #private method
      def votes=
        if self.votes_available?
          @votes = Wagg::Crawler::Vote.parse_news_votes(@self.id)
        end
      end

      def to_s
        "%{id} :: %{a} - %{ts}" % {id:@id, a:@author, ts:@timestamps} +
            "\n" +
            "  %{t} (%{cat})" % {t:@title, cat:@category} +
            "\n" +
            "  %{d}" % {d:@description} +
            "\n" +
            "  %{u}" % {u:@urls} +
            "\n" +
            "  %{k} :: %{vc} - %{c}" % {k:@karma, vc:@votes_count, c:@clicks} +
            "\n" +
            "  %{v}" % {v:(@votes.nil? ? nil : @votes.size)} +
            "\n" +
            "  %{tg}" % {tg:(@tags.nil? ? nil: @tags)} +
            "\n" +
            "  %{co}" % {co:(@comments.nil? ? nil : @comments.size)}
      end

      class << self

        def parse_summary(item)
          # Retrieve main news body DOM subtree
          body_item = item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-body ")]')

          # Parse title and unique id
          news_title = Wagg::Utils::Functions.str_at_xpath(body_item, './*[self::h1 or self::h2]/a/text()')
          news_id = Wagg::Utils::Functions.str_at_xpath(body_item, './*[self::h1 or self::h2]/a/@class')[/(?<id>\d+)/].to_i

          # Parse (brief) description as text
          # TODO: Possibly parse the full node instead (think of anything that is not text such as links,...)
          news_description = Wagg::Utils::Functions.str_at_xpath(body_item, './text()[normalize-space()]')

          # Parse URLs (internal and external)
          news_urls = Hash.new
          news_urls['external'] = Wagg::Utils::Functions.str_at_xpath(body_item, './*[self::h1 or self::h2]/a/@href')
          internal_url_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " votes ")]')
          news_urls['internal'] = Wagg::Utils::Constants::SITE_URL + Wagg::Utils::Functions.str_at_xpath(internal_url_item, './a/@href')

          # Retrieve main news meta-data DOM subtree
          meta_item = body_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-submitted ")]')

          # Parse sending and publishing timestamps
          news_timestamps = Hash.new
          timestamp_items = meta_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " ts ")]')
          for t in timestamp_items
            case Wagg::Utils::Functions.str_at_xpath(t, './@title')
              when /\Aenviado:/
                news_timestamps["creation"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
              when /\Apublicado:/
                news_timestamps["publication"] = Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i
            end
          end

          # Parse author of news post (NOT the author(s) of the news itself as we don't know/care)
          author_item = meta_item.search('./a[contains(concat(" ", normalize-space(@class), " "), " tooltip ")]')
          news_author = Hash.new
          news_author["id"] = Wagg::Utils::Functions.str_at_xpath(author_item, './@class')[/(?<author_id>\d+)/].to_i
          news_author["name"] = Wagg::Utils::Functions.str_at_xpath(author_item, './@href')[/\/user\/(?<author_name>.+)/,1]

          # Parse votes count: up-votes (registered and anonymous users) and down-votes (registered users)
          details_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " news-details ")]')
          news_votes_count = Hash.new
          news_votes_count["positive"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span[@id="a-usu-%{id}"]/text()' % {id:news_id}).to_i
          news_votes_count["negative"] = Wagg::Utils::Functions.str_at_xpath(details_item, './span[@id="a-neg-%{id}"]/text()' % {id:news_id}).to_i
          news_votes_count["anonymous"] = Wagg::Utils::Functions.str_at_xpath(details_item, './/span[@id="a-ano-%{id}"]/text()' % {id:news_id}).to_i

          # Parse number of clicks
          clicks_item = body_item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " clics ")]')
          news_clicks = Wagg::Utils::Functions.str_at_xpath(clicks_item, './text()')[/(?<id>\d+)/].to_i

          # Parse comments' count
          news_comments_count = Wagg::Utils::Functions.str_at_xpath(details_item, './span/a/span[contains(concat(" ", normalize-space(@class), " "), " counter ")]/text()').to_i

          # Retrieve secondary news meta-data DOM subtree
          others_item = details_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " tool ")]')

          # Parse category
          news_category = Wagg::Utils::Functions.str_at_xpath(others_item, './a/@href')[/\/m\/(?<category>.+)/,1]

          # Parse karma (accumulative sum of users' votes, i.e., news weight)
          news_karma = Wagg::Utils::Functions.str_at_xpath(others_item, './span[@id="a-karma-%{id}"]/text()' % {id:news_id}).to_i

          # Create the news object (we only create it with data that won't 'change' over time)
          news = News.new(news_id, news_title, news_author, news_description, news_urls, news_timestamps, news_category)
          # Fill the remaining details (the timestamps will tell us whether the information is final or not)
          news.clicks = news_clicks
          news.karma = news_karma
          # TODO: Find an alternative to this (we should rely on the information on the webpage not this that may change)
          news.comments_count = news_comments_count
          news.votes_count = news_votes_count

          # Return the object containing the summary of the news (no votes, comments, tags details)
          news
        end

        def parse(item, parse_comments=FALSE, parse_votes=FALSE)

          # Parse the summary of the news (same information we would get from the front page)
          news_summary_item = item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')

          puts 'Parsing news summary'
          news = News.parse_summary(news_summary_item)

          # Parse the remaining items of the news that we cannot get from the view of the front page but should be available
          body_item = news_summary_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-body ")]')

          puts 'Parsing tags'
          # Parse tags
          news_tags = News.parse_tags(body_item)

          puts 'Parsing comments'
          # Parse comments (and each comment votes if available)
          news_comments = nil
          if parse_comments
            comments_item = item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
            news_comments = News.parse_comments(comments_item, news.urls['internal'])
          end

          puts 'Parsing votes'
          # Parse votes (if available and configured)
          news_votes = nil
          if parse_votes
            news_votes = News.parse_votes(news.id)
          end

          # Add parsed items to the news summary and return it (as a full parsed news now)
          news.tags = news_tags
          #news.votes = news_votes
          news.votes
          news.comments = news_comments

          # Return the object containing the full news (with votes, comments and tags details)
          news
        end

        def parse_tags(item)
          tags_item = item.search('.//span[contains(concat(" ", normalize-space(@class), " "), " news-tags ")]/a')

          news_tags = Array.new
          for t in tags_item
            news_tags.push(Wagg::Utils::Functions.str_at_xpath(t, './text()').strip)
          end

          news_tags
        end

        def parse_comments(item, news_url_internal)
          # Find out how many pages of comments there are (at least one, the news page)
          pages_item = item.search('./div[contains(concat(" ", normalize-space(@class), " "), " pages ")]/a')
          (pages_item.count != 0) ? pages_total = pages_item.count : pages_total = 1

          news_comments = Hash.new
          pages_counter = 1
          begin
            if pages_total > 1
              comments_page = Wagg::Utils::Retriever.instance.get("%{url}/%{page}" % {url:news_url_internal, page:pages_counter}, 'news')
              comments_item = comments_page.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/div')
            else
              comments_item = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/div')
            end
            puts comments_item.length
            for c in comments_item
              puts 'Parsing one comment'
              comment = Wagg::Crawler::Comment.parse(c, TRUE)
              news_comments[comment.news_id] = comment
            end

            pages_counter += 1
          end while ( pages_counter <= pages_total )

          news_comments
        end

        def parse_votes(item)
          news_votes = Vote.parse_news_votes(item)

          news_votes
        end

      end

    end
  end
end