# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Author
      attr_accessor :id, :name
      attr_accessor :creation

      def initialize(id, name, creation)
        @id = id
        @name = name
        @creation = creation
      end

      def to_s
        "AUTHOR : %{id} - %{n} (%{c})" % {id:@id, n:@name, c:@creation} + "\n"
      end

      class << self
        def parse(item)

          table_item = item.search('./fieldset/table')

          author_username = Wagg::Utils::Functions.str_at_xpath(table_item, './tr[1]/td/text()')
          author_timestamp = DateTime.strptime(Wagg::Utils::Functions.str_at_xpath(table_item, './tr[2]/td/text()'),'%d-%m-%Y %H:%M %Z').to_time.to_i
          author_id = Wagg::Utils::Functions.str_at_xpath(item, './ul/li[2]/a/@href')[/(?<id>\d+)/].to_i

          author = Wagg::Crawler::Author.new(
              author_id,
              author_username,
              author_timestamp
          )

          author
        end
      end
    end
  end
end

