# encoding: utf-8

require 'wagg/crawler/news'

module Wagg
  module Crawler
    class Page

      class << self
        # Parse list of news
        def parse(item, begin_interval=1, end_interval='all', with_comments=FALSE, with_votes=FALSE)
          news_list = Array.new

          # Retrieve main list of news summaries DOM subtree
          news_internal_urls_list = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " votes ")]/a')
          #Wagg::Utils::Constants::SITE_URL + Wagg::Utils::Functions.str_at_xpath(internal_url_item, './a/@href')

          # Figure out the interval of news items to retrieve in the page
          if begin_interval < 1 then
            nil
          end
          if end_interval != 'all' and begin_interval > end_interval
            nil
          end

          # Parse list of news
          news_internal_urls_list.each do |news_url_item|
            Wagg::Utils::Retriever.instance.agent('news', Wagg::Utils::Constants::RETRIEVAL_DELAY['news'])

            news_url = Wagg::Utils::Constants::SITE_URL + Wagg::Utils::Functions.str_at_xpath(news_url_item, './@href')
            news = Wagg::Utils::Retriever.instance.get(news_url, 'news')

            news_item = news.search('//*[@id="newswrap"]')
            news_summary_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')
            news_comments_item = news_item.search('./div[contains(concat(" ", normalize-space(@class), " "), " comments ")]')

            news_list.push(Wagg::Crawler::News.parse(news_summary_item, news_comments_item, with_comments, with_votes))
            puts news_list
            exit(0)
          end

          news_list
        end

        # Parse list of news summaries
        def parse_summaries(item)
          news_list = Array.new

          # Retrieve main list of news summaries DOM subtree
          news_summary_items = item.search('.//div[contains(concat(" ", normalize-space(@class), " "), " news-summary ")]')

          # Parse list of news summaries
          news_summary_items.each do |news_summary_item|
            news_object = Wagg::Crawler::News.parse_summary(news_summary_item)
            news_list.push(news_object)
          end

          news_list
        end
      end
    end
  end
end