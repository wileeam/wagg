# encoding: UTF-8

module Wagg
  module Utils
    module Functions
      def self.text_at_css(root, css=nil)
        raw_element = root
        unless css.nil?
          raw_element = root.at_css(css)
        end

        if raw_element.nil?
          nil
        else
          raw_element.text().scrub.strip
        end
      end

      def self.text_at_xpath(root, xpath=nil, transliterate=false)
        raw_element = nil
        unless xpath.nil?
          raw_element = root.at_xpath(xpath)
        end

        if raw_element.nil?
          nil
        else
          raw_element.to_s.scrub.strip
        end
      end

      def self.datetime_to_text(dt, format='%Y-%m-%d %H:%M:%S%z')
        dt.strftime(format)
      end

      def self.datetime_to_unix(dt)
        dt.strftime('%s').to_i
      end

      def self.timestamp_to_text(t, format='%Y-%m-%d %H:%M:%S%z')
        t.strftime(format)
      end

      def self.timestamp_to_unix(t)
        t.strftime('%s').to_i
      end

      def self.hash_str_datetime_to_json(hash, unixtime = false)
        h = {}
        hash.each do |key, datetime|
          h[key] = nil
          unless datetime.nil?
            if unixtime
              h[key] = datetime_to_unix(datetime)
            else
              h[key] = datetime_to_text(datetime)
            end
            
          end
        end

        h
      end

    end
  end
end