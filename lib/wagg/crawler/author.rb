# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Author
      attr_reader :id, :name, :karma
      attr_reader :creation
      attr_reader :disabled

      def initialize(name)
        @name = name
        @disabled = FALSE
        parse_author(name)
      end

      def to_s
        "AUTHOR : %{n} :: %{id} - (%{k}) (%{c})" % {id:@id, k:@karma, n:@name, c:Time.at(@creation)}
      end

      def parse_author(name)
        Wagg::Utils::Retriever.instance.agent('author', Wagg.configuration.retrieval_delay['author'])

        author_item = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_URL % {author:name}, 'author')
        author_table_items = author_item.search('//*[@id="singlewrap"]/fieldset/table[contains(concat(" ", normalize-space(@class), " "), " keyvalue ")]/tr')

        for i in author_table_items
          case Wagg::Utils::Functions.str_at_xpath(i, './th/text()')
            when /\Adesde:/
              @creation = DateTime.strptime(Wagg::Utils::Functions.str_at_xpath(i, './td/text()'),'%d-%m-%Y %H:%M %Z').to_time.to_i
            when /\Anombre:/
              if Wagg::Utils::Functions.str_at_xpath(i, './td/text()').eql?('disabled')
                @disabled = TRUE
              end
            when /\Akarma:/
              @karma = Wagg::Utils::Functions.str_at_xpath(i, './td/text()').to_f
          end
        end

        @id = Wagg::Utils::Functions.str_at_xpath(author_item.search('//*[@id="singlewrap"]'), './ul/li[2]/a/@href')[/(?<id>\d+)/].to_i
        @name = Wagg::Utils::Functions.str_at_xpath(author_item.search('//*[@id="singlewrap"]'), './ul/li[1]/a/text()')
      end

      private :parse_author

      class << self
        def parse(name)
          Author.new(name)
        end
      end

    end
  end
end

