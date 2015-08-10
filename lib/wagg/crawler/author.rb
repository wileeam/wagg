# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Author
      attr_accessor :id, :name
      attr_accessor :creation
      attr_accessor :disabled

      def initialize(id, name)
        @id = id
        @name = name
      end

      def to_s
        "AUTHOR : %{id} - %{n} (%{c})" % {id:@id, n:@name, c:@creation} + "\n"
      end

      class << self
        def parse(item)

          table_items = item.search('./fieldset/table[contains(concat(" ", normalize-space(@class), " "), " keyvalue ")]/tr')

          author_items = Hash.new
          for i in table_items
            case Wagg::Utils::Functions.str_at_xpath(i, './th/text()')
              when /\Adesde:/
                author_items["creation"] = DateTime.strptime(Wagg::Utils::Functions.str_at_xpath(i, './td/text()'),'%d-%m-%Y %H:%M %Z').to_time.to_i
              when /\Anombre:/
                if Wagg::Utils::Functions.str_at_xpath(i, './td/text()').eql?('disabled')
                  author_items["disabled"] = TRUE
                end
            end
          end
          author_items["username"] = Wagg::Utils::Functions.str_at_xpath(item, './ul/li[1]/a/text()')
          author_items["id"] = Wagg::Utils::Functions.str_at_xpath(item, './ul/li[2]/a/@href')[/(?<id>\d+)/].to_i

          author = Wagg::Crawler::Author.new(
              author_items["id"],
              author_items["username"]
          )

          unless author_items["creation"].nil?
            author.creation = author_items["creation"]
          end

          if author_items["disabled"].nil?
            author.disabled = FALSE
          else
            author.disabled = author_items["disabled"]
          end

          author
        end
      end
    end
  end
end

