# encoding: utf-8

require 'wagg/utils/retriever'
require 'wagg/crawler/page'


module Wagg
  module Crawler
    class Crawler

      class << self
        def parse_single(item)
          Wagg::Crawler::Crawler.parse_interval(item, item)
        end

        def parse_page_interval(begin_interval=1, end_interval=1, only_summaries=FALSE)

          news_list = Array.new

          Wagg::Utils::Retriever.instance.agent('main', 10)

          # Retrieve first page to learn the hard limit on the end_interval that we can have
          # TODO: Can we do better than this (tested that there are pages with more than one 'nofollow')?
          page_one = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:1}, 'main')
          end_interval_item = page_one.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " pages ")]')
          max_end_interval = Wagg::Utils::Functions.str_at_xpath(end_interval_item, './a[@rel="nofollow"]/text()').to_i


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
            page = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::PAGE_URL % {page:p}, 'main')
            page_item = page.search('//*[@id="newswrap"]')
            news_list.concat(Wagg::Crawler::Page.parse(page_item,1,'all',only_summaries))
            puts news_list
            exit(-1)
          end

          news_list
        end


        def news(url, votes=false, comments=false)
          self::News.parse(url)
        end

        def comment(url, votes=false)
          self::Comment.parse(url)
        end
      end

    end

  end
end
