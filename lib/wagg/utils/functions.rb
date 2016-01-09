# encoding: utf-8

require 'wagg/utils/retriever'

module Wagg
  module Utils
    module Functions
      def self.str_at_xpath(root, xpath)
        element = root.at_xpath(xpath)
        element.nil? ? nil : element.to_s.scrub.strip
      end
    end
  end
end

