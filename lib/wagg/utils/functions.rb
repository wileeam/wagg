# encoding: utf-8

require 'wagg/utils/retriever'

module Wagg
  module Utils
    module Functions
      def self.str_at_xpath(root, xpath)
        element = root.at_xpath(xpath)
        element.nil? ? nil : element.to_s.scrub.strip
      end

      def self.filter_page_interval(begin_interval=1, end_interval='all', type)
        # Get first page of website for reference
        page_one = Retriever.instance.get(Constants::PAGE_URL[type] % {page:1}, 'main')
        # Find the DOM item containing the navigation buttons for pages
        max_end_interval_item = page_one.search('//*[@id="newswrap"]/div[contains(concat(" ", normalize-space(@class), " "), " pages ")]')
        # Parse the maximum number of pages to a number
        # TODO: Can we do better than this (tested that there are pages with more than one 'nofollow')?
        max_end_interval = str_at_xpath(max_end_interval_item, './a[@rel="nofollow"]/text()').to_i

        filtered_begin_interval = begin_interval
        if begin_interval == 'all' || begin_interval > max_end_interval
          filtered_begin_interval = max_end_interval
        elsif begin_interval < 1
          filtered_begin_interval = 1
        end

        filtered_end_interval = end_interval
        if end_interval == 'all' || end_interval > max_end_interval
          filtered_end_interval = max_end_interval
        elsif end_interval < 1
          filtered_end_interval = 1
        end

        return filtered_begin_interval, filtered_end_interval
      end
    end
  end
end

