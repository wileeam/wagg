module Wagg
  module Crawler
    class Author
      attr_reader :name
      attr_reader :signup
      attr_reader :karma
      attr_reader :ranking
      attr_reader :timestamp

      def initialize(name)
        @id = nil
        @name = name
        @disabled = false
        #parse_author(name)

        @timestamp = Time.now.utc.to_f
      end

      class << self
        def parse(name)
          Author.new(name)
        end
      end

      def disabled
        !@name.match(/^--(?<id>\d+)--$/).nil?
      end

      def parse_element(element, tree)

        author_item = Wagg::Utils::Retriever.instance.get(Wagg::Constants::Author::MAIN_URL % {author:name}, 'author')


        author_history_item = Wagg::Utils::Retriever.instance.get(Wagg::Utils::Constants::AUTHOR_HISTORY_URL % {author:name}, 'author')

        author_history_header_item = author_history_item.css('div#header div.header-menu01')
        author_id = author_history_header_item.at_css('div.dropdown.menu-more > ul > li.icon.wideonly > a')['href'][/(?<id>\d+)/].to_i

        author_id
      end


      def to_s
        "AUTHOR : %{n} :: %{id} - (%{k}) (%{c})" % {id:(@id.nil? ? 'EMPTY' : @id), k:@karma, n:@name, c:Time.at(@creation)}
      end

      def as_json(options={})
        {
            type: self.class.name.downcase,
            timestamp: @timestamp,
            data: {
                id: @id,
                name: @name,
                signup: @signup,
                karma: @karma,
                ranking: @ranking,
                disabled: @disabled,
            }
        }
      end

      def to_json(*options)
        as_json(*options).to_json(*options)
      end

    end
  end
end