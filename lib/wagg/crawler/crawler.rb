# encoding: utf-8

require 'wagg/utils/retriever'
require 'wagg/crawler/page'
require 'wagg/crawler/author'


module Wagg
  module Crawler
    class Crawler

      class << self
        def page_single(item, with_comments=FALSE, with_votes=FALSE)
          Wagg::Crawler::Crawler.page_interval(item, item, with_comments, with_votes)
        end

        def page_interval(begin_interval=1, end_interval=1, with_comments=FALSE, with_votes=FALSE)

          news_list = Array.new

          Wagg::Utils::Retriever.instance.agent('page', Wagg::Utils::Constants::RETRIEVAL_DELAY['page'])

          # Retrieve first page to learn the hard limit on the end_interval that we can have
          # TODO: Can we do better than this (tested that there are pages with more than one 'nofollow')?
          page_one = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:1}, 'main')
          max_end_interval_item = page_one.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " pages ")]')
          max_end_interval = Wagg::Utils::Functions.str_at_xpath(max_end_interval_item, './a[@rel="nofollow"]/text()').to_i

          # parameters cannot be negative, zero nor greater than maximum
          if 1 > begin_interval
            nil
          end
          if 1 > end_interval
            nil
          end
          if max_end_interval < begin_interval
            nil
          end
          if max_end_interval < end_interval
            nil
          end
          if begin_interval > end_interval
            nil
          end

          for p in begin_interval..end_interval
            page = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:p}, 'page')
            news_list.concat(Wagg::Crawler::Page.parse(page, 1, 'all', with_comments, with_votes))
          end

          news_list
        end

        def author(name)
          Wagg::Utils::Retriever.instance.agent('author', Wagg::Utils::Constants::RETRIEVAL_DELAY['author'])

          author = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_URL % {name:name}, 'author')
          author_item = author.search('//*[@id="singlewrap"]')

          Wagg::Crawler::Author.parse(author_item)
        end

        def news(url, with_comments=FALSE, with_votes=FALSE)
          Wagg::Utils::Retriever.instance.agent('news', Wagg::Utils::Constants::RETRIEVAL_DELAY['news'])

          news = Wagg::Utils::Retriever.instance.get(url, 'news')
          news_item = news.search('//*[@id="newswrap"]')
          news_summary_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')
          news_comments_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')

          Wagg::Crawler::News.parse(news_summary_item, news_comments_item, with_comments, with_votes)
        end

        def comment(url, with_comments=FALSE, with_votes=FALSE)
          Wagg::Utils::Retriever.instance.agent('comment', Wagg::Utils::Constants::RETRIEVAL_DELAY['comment'])
          self::Comment.parse(url)
        end
      end

    end

  end
end
