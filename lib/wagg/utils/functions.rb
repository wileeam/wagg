# encoding: utf-8

module Wagg
  module Utils
    module Functions
      def self.str_at_xpath(root, xpath)
        element = root.at_xpath(xpath)
        element.nil? ? nil : element.to_s.strip
      end
    end
  end
end

