# encoding: utf-8

require 'wagg/crawler/comment'

module Wagg
  module Crawler
    class News
      attr_accessor :id, :title, :author, :description, :category, :urls, :timestamps
      attr_accessor :karma, :votes_count, :clicks, :votes
      # TODO: Remove this attribute, not reliable if news is still open for commenting
      attr_accessor :comments_count
      attr_accessor :tags
      attr_accessor :comments

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
        closed_item = @raw.search('.//div[contains(concat(" ", normalize-space(@class), " "), " menealo ")]')
        span_object = closed_item.search('./span')
        (!span_object.nil? && Wagg::Utils::Functions.str_at_xpath(span_object, './text()') == 'menealo') ? TRUE : FALSE
      end

      def open?
        !self.closed?
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
          news_timestamps = Array.new
          timestamp_items = meta_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " ts ")]')
          for t in timestamp_items
            case Wagg::Utils::Functions.str_at_xpath(t, './@title')
              when /\Aenviado:/
                news_timestamps.unshift(Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i)
              when /\Apublicado:/
                news_timestamps.push(Wagg::Utils::Functions.str_at_xpath(t, './@data-ts').to_i)
            end
          end

          # Parse author of news post (NOT the author of the news itself, that we don't know/care)
          author_item = meta_item.search('./a[contains(concat(" ", normalize-space(@class), " "), " tooltip ")]')
          news_author = Wagg::Utils::Functions.str_at_xpath(author_item, './@href')[/\/user\/(?<author>.+)/,1]

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

        def parse(item)
          # Parse the summary of the news (same information we would get from the front page)
          news = News.parse_summary(item)

          # We cannot reuse item DOM element because it does not contain the full news, so load news via Mechanize
          # TODO: Can we do better than this? Maybe methods to parse via URL (and Mechanize.agent) and via DOM?
          Wagg::Utils::Retriever.instance.agent('news', 60)

          page = Wagg::Utils::Retriever.instance.get(news.urls['internal'], 'news')

          # Parse the remaining items of the news that we cannot get from the view of the front page but should be available
          body_item = page.search('//*[@id="newswrap"]//div[contains(concat(" ", normalize-space(@class), " "), " news-body ")]')

          # Parse tags
          tags_item = body_item.search('./span[contains(concat(" ", normalize-space(@class), " "), " news-tags ")]/a')
          news_tags = Array.new
          for t in tags_item
            news_tags.push(Wagg::Utils::Functions.str_at_xpath(t, './text()').strip)
          end

          # Parse votes (if available)
          news_votes = Wagg::Crawler::Vote.parse_news_votes(news.id)
          if news_votes.empty?
            news_votes = nil
          end

          # Parse comments (and each comment votes if available)
          news_comments = Array.new
          unless news.comments_count.nil?
            if news.comments_count.to_i <= 100
              comments_item = page.search('//*[@id="newswrap"]//div[contains(concat(" ", normalize-space(@class), " "), " comments ")]//div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/div')
              for c in comments_item
                comment = Wagg::Crawler::Comment.parse(c)
                news_comments.push(comment)
              end
            else
              comments_page_index = 1
              begin
                comments_page = Wagg::Utils::Retriever.instance.get("%{url}/%{page}" % {url:news.urls['internal'], page:comments_page_index}, 'news')
                comments_item = comments_page.search('.//div[contains(concat(" ", normalize-space(@class), " "), " comments ")]/ol/li/div')
                for c in comments_item
                  comment = Wagg::Crawler::Comment.parse(c)
                  news_comments.push(comment)
                end
                comments_page_index += 1
              end while comments_page_index <= (news.comments_count.to_i / 100.0).ceil
            end

          end

          # Add parsed items to the news summary and return it (as a full parsed news now)
          news.tags = news_tags
          news.votes = news_votes
          news.comments = news_comments

          # Return the object containing the full news (with votes, comments and tags details)
          news
        end
      end

    end
  end
end