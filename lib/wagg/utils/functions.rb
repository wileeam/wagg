# frozen_string_literal: true

module Wagg
  module Utils
    module Functions
      def self.text_at_css(root, css = nil)
        raw_element = root
        raw_element = root.at_css(css) unless css.nil?

        # raw_element.nil? == root.at(css).nil?
        if raw_element.nil?
          nil
        else
          raw_element.text.scrub.strip
        end
      end

      def self.text_at_xpath(root, xpath = nil)
        raw_element = nil
        raw_element = root.at_xpath(xpath) unless xpath.nil?

        # raw_element.nil? == root.at(css).nil?
        if raw_element.nil?
          nil
        else
          raw_element.to_s.scrub.strip
        end
      end

      def self.datetime_to_text(dt, format = '%Y-%m-%d %H:%M:%S%z')
        dt.strftime(format)
      end

      def self.datetime_to_unix(dt)
        dt.strftime('%s').to_i
      end

      def self.timestamp_to_text(t, format = '%Y-%m-%d %H:%M:%S%z')
        t.strftime(format)
      end

      def self.timestamp_to_unix(t)
        t.strftime('%s').to_i
      end

      def self.hash_str_datetime_to_json(hash, unixtime = false)
        h = {}
        hash.each do |key, datetime|
          h[key] = nil
          next if datetime.nil?

          h[key] = if unixtime
                     datetime_to_unix(datetime)
                   else
                     datetime_to_text(datetime)
                   end
        end

        h
      end
    end
  end
end
