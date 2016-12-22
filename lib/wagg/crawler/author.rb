# encoding: utf-8

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Crawler
    class Author
      attr_reader :name, :karma
      attr_reader :creation
      attr_reader :disabled

      def initialize(name)
        @id = nil
        @name = name
        @disabled = FALSE
        parse_author(name)
      end

      def id
        if @id.nil?
          @id = parse_author_id(name)
        end

        @id
      end

      def to_s
        "AUTHOR : %{n} :: %{id} - (%{k}) (%{c})" % {id:(@id.nil? ? 'EMPTY' : @id), k:@karma, n:@name, c:Time.at(@creation)}
      end

      def disabled
        !@name.match(/^--(?<id>\d+)--$/).nil?
      end

      def parse_author(name)
        author_item = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_URL % {author:name}, 'author')

        author_retrieval_timestamp = Time.now.utc + Wagg.configuration.retrieval_delay['author']

        #author_table_items = author_item.search('//*[@id="singlewrap"]/fieldset/table[contains(concat(" ", normalize-space(@class), " "), " keyvalue ")]/tr')
        author_table_items = author_item.css('div#singlewrap > section > fieldset > table tr')

        for i in author_table_items
          case Wagg::Utils::Functions.str_at_xpath(i, './th/text()')
            when /\Adesde:/
              author_date = Wagg::Utils::Functions.str_at_xpath(i, './td/text()')
              if author_date.match(/\A\d{1,2}:\d{1,2}\s[A-Z]+\z/)
                author_date = author_retrieval_timestamp.day.to_s +
                    '-' +
                    author_retrieval_timestamp.month.to_s +
                    '-' +
                    author_retrieval_timestamp.year.to_s +
                    ' ' +
                    author_date
              end
              @creation = DateTime.strptime(author_date,'%d-%m-%Y %H:%M %Z').to_time.to_i
            when /\Anombre:/
              if Wagg::Utils::Functions.str_at_xpath(i, './td/text()').eql?('disabled')
                @disabled = TRUE
              end
            when /\Ausuario:/
              # @name == name
              @name = i.at_css('td').text.strip
            when /\Akarma:/
              @karma = Wagg::Utils::Functions.str_at_xpath(i, './td/text()').to_f
          end
        end
      end

      def parse_author_id(name)
        author_history_item = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_HISTORY_URL % {author:name}, 'author')

        author_history_header_item = author_history_item.css('div#header div.header-menu01')
        author_id = author_history_header_item.at_css('div.dropdown.menu-more > ul > li.icon.wideonly > a')['href'][/(?<id>\d+)/].to_i

        author_id
      end

      private :parse_author, :parse_author_id

      class << self
        def parse(name)
          Author.new(name)
        end
      end

    end
  end
end

