# encoding: utf-8

require 'wagg/utils/retriever'
require 'wagg/crawler/page'
require 'wagg/crawler/author'
require 'wagg/crawler/comment'


module Wagg
  module Crawler

        def self.page_single(item, with_comments=FALSE, with_votes=FALSE)
          Wagg::Crawler::Crawler.page_interval(item, item, with_comments, with_votes)
        end

        def self.page_interval(begin_interval=1, end_interval=1, with_comments=FALSE, with_votes=FALSE)

          news_list = Array.new

          Wagg::Utils::Retriever.instance.agent('page', Wagg::Utils::Constants::RETRIEVAL_DELAY['page'])

          filtered_begin_interval, filtered_end_interval = self.filter_page_interval_limits(begin_interval,end_interval)
          for p in filtered_begin_interval..filtered_end_interval
            page = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:p}, 'page')
            news_list.concat(Wagg::Crawler::Page.parse(page, 1, 'all', with_comments, with_votes))
          end

          news_list
        end

        # TODO
        def self.author(name)
          Wagg::Utils::Retriever.instance.agent('author', Wagg::Utils::Constants::RETRIEVAL_DELAY['author'])

          author = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_URL % {name:name}, 'author')
          author_item = author.search('//*[@id="singlewrap"]')

          Wagg::Crawler::Author.parse(author_item)
        end

        def self.news(url, with_comments=FALSE, with_votes=FALSE)
          Wagg::Utils::Retriever.instance.agent('news', Wagg::Utils::Constants::RETRIEVAL_DELAY['news'])

          news = Wagg::Utils::Retriever.instance.get(url, 'news')
          news_item = news.search('//*[@id="newswrap"]')
          news_summary_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')
          news_comments_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')

          Wagg::Crawler::News.parse(news_summary_item, news_comments_item, with_comments, with_votes)
        end

        def self.get_news_urls(begin_page_interval=1, end_page_interval='all')

          news_internal_urls_list = Hash.new
          filtered_begin_interval, filtered_end_interval = Wagg::Crawler.filter_page_interval_limits(begin_page_interval, end_page_interval)

          (filtered_begin_interval..filtered_end_interval).each do |index|
            news_internal_urls_list[index] = Page.new(index).news_urls
          end

          news_internal_urls_list
        end

        # TODO
        def self.comment(comment_id, with_votes=FALSE)
          Wagg::Utils::Retriever.instance.agent('comment', Wagg::Utils::Constants::RETRIEVAL_DELAY['comment'])
          Wagg::Utils::Retriever.instance.agent('news', Wagg::Utils::Constants::RETRIEVAL_DELAY['news'])

          comment = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::COMMENT_URL % {comment:comment_id} , 'comment')
          comments_list_item = comment.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')
          # Note that at() is the same as search().first
          comment_item = comments_list_item.at('./div[contains(concat(" ", normalize-space(@class), " "), " threader ")]/div')

          comment_news_item = comment.search('//*[@id="newswrap"]/h3')
          comment_news_internal_url = Wagg::Utils::Functions.str_at_xpath(comment_news_item, './a/@href')
          comment_news = Wagg::Crawler.news(comment_news_internal_url, FALSE, FALSE)

          comment_object = Wagg::Crawler::Comment.parse(comment_item, comment_news.timestamps, with_votes)
          puts comment_object
          exit(0)

          comment_object
        end

        def self.filter_page_interval_limits(begin_interval=1, end_interval='all')

          # Get first page of website for reference
          page_one = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:1}, 'main')
          # Find the DOM item containing the navigation buttons for pages
          max_end_interval_item = page_one.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " pages ")]')
          # Parse the maximum number of pages to a number
          # TODO: Can we do better than this (tested that there are pages with more than one 'nofollow')?
          max_end_interval = Wagg::Utils::Functions.str_at_xpath(max_end_interval_item, './a[@rel="nofollow"]/text()').to_i

          filtered_begin_interval = 1
          filtered_end_interval = max_end_interval

          begin_interval = max_end_interval if begin_interval == 'all'
          end_interval = max_end_interval if end_interval == 'all'

          if begin_interval > end_interval
            filtered_begin_interval = max_end_interval
          elsif begin_interval > 0 && begin_interval <= max_end_interval
            filtered_begin_interval = begin_interval
            if end_interval <= max_end_interval
              filtered_end_interval = end_interval
            end
          end

          return filtered_begin_interval, filtered_end_interval
        end

  end

end
