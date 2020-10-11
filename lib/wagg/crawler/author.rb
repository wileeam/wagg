# encoding: UTF-8

require 'wagg/utils/functions'

module Wagg
  module Crawler
    class FixedAuthor
      # @!attribute [r] name
      #   @return [String] the name of the author
      attr_reader :name
      # @!attribute [r] id
      #   @return [String] the unique id of the author
      attr_reader :id

      def initialize(name, id = nil, snapshot_timestamp = nil)
        @name = name
        if disabled
          id_matched = @name.match(/^--(?<id>\d+)--$/)
          @id = id_matched[:id]
        else
          @id = id
        end
        
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
      end


      def disabled
        @name.match?(/^--(?<id>\d+)--$/)
      end
    end

    class Author < FixedAuthor
      attr_reader :fullname # Can be nil
      attr_reader :signup
      attr_reader :karma
      attr_reader :ranking
      attr_reader :entropy # Can be nil
      attr_reader :friends
      attr_reader :friends_of
      attr_reader :subs_own
      attr_reader :subs_follow

      attr_reader :snapshot_timestamp

      def initialize(name, id = nil, snapshot_timestamp = nil)
        super(name, id)

        author_uri = format(::Wagg::Constants::Author::PROFILE_URL, author: @name)
        @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
        @raw_data = get_data(author_uri)

        # When a user does not exist (@name is not valid) the site redirects to the frontpage
        raise('Author does not exist') if author_uri != @raw_data.uri.to_s

        # Each parse_xxx() function issues one GET request
        # TODO: Make these class methods rather than instance ones?
        if id.nil?
          if disabled
            parse_id()
          else
            parse_id()
          end
        else
          @id = id
        end
        parse_profile()
        parse_subs_own()
        parse_subs_follow()
        parse_friends()
        parse_friends_of()
        parse_subs_own()
        parse_subs_follow()
        # parse_notes()

      end

      class << self
        def parse(name)
          author = Author.new(name)

          author
        end
      end

      def get_data(uri, retriever = nil, retriever_type = ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['author'])
        if retriever.nil?
          local_retriever = ::Wagg::Utils::Retriever.instance
          credentials = ::Wagg::Settings.configuration.credentials
        else
          credentials = ::Wagg::Settings.configuration.credentials
        end

        agent = local_retriever.agent(retriever_type)
        page = agent.get uri
        # page.encoding = 'utf-8'
        # page.body.force_encoding('utf-8')
        page
      end

      def parse_id
        id_item = @raw_data.css('#avatar')
        avatar_source_item = ::Wagg::Utils::Functions.text_at_xpath(id_item,'./@src')

        if avatar_source_item.match?(::Wagg::Constants::Author::AVATAR_REGEX)
          matched_id = avatar_source_item.match(::Wagg::Constants::Author::AVATAR_REGEX)
          @id = matched_id[:id]
        end

      end

      def parse_profile
        profile_uri = format(::Wagg::Constants::Author::PROFILE_URL, author: @name)
        profile_raw_data = get_data(profile_uri)

        profile_table_items = profile_raw_data.css('div#container > section > div.contents-layout > div.contents-body > table tr')

        profile_items = {}
        profile_table_items.each do |item|
          k = ::Wagg::Utils::Functions.text_at_css(item, 'th').downcase
          v = item.css('td')
          profile_items[k] = v
        end

        profile_name_key = 'Usuario'.downcase
        profile_name = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_name_key])
        if @name == profile_name
          profile_signup_key ='Desde'.downcase
          profile_signup = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_signup_key])
          @signup = DateTime.strptime(profile_signup, '%d-%m-%Y %H:%M %Z')

          profile_fullname_key = 'Nombre'.downcase
          if profile_items.key?(profile_fullname_key)
            @fullname = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_fullname_key])
          end

          profile_karma_key = 'Karma'.downcase
          profile_karma = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_karma_key])
          @karma = profile_karma.to_f

          # The following drama addresses some strange encoding issue, so we match the field name partially...
          profile_entropy_key = 'Entropía'.downcase
          profile_items_entropy_index = nil
          profile_items_entropy_key = nil
          profile_items.keys.each_with_index do |key, index|
            if key.include? 'Entrop'.downcase
              profile_items_entropy_index = index
              profile_items_entropy_key = key
            end
          end
          unless profile_items_entropy_index.nil?
            profile_items[profile_entropy_key] = profile_items.delete profile_items_entropy_key
          end
          if profile_items.key?(profile_entropy_key)
            profile_entropy = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_entropy_key])
            matched_entropy = profile_entropy.match(/\A(?<entropy>\d{1,3})%\z/)
            @entropy = matched_entropy[:entropy].to_i
          end

          profile_ranking_key = 'Ranking'.downcase
          profile_ranking = ::Wagg::Utils::Functions.text_at_css(profile_items[profile_ranking_key])
          matched_ranking = profile_ranking.match(/\A#(?<ranking>\d\.\d{3}|\d{1,3})(?<K>K)?\z/)
          @ranking = matched_ranking[:ranking].tr('.', '').to_i
          @ranking *= 1000 if matched_ranking.names.include?('K') && matched_ranking[:K] == 'K'

        end
      end

      def parse_friends
        friends_uri = ::Wagg::Constants::Author::FRIENDS_URL % {author: @name}
        friends = parse_relationships(friends_uri)
        @friends = friends
      end

      def parse_friends_of
        friends_of_uri = ::Wagg::Constants::Author::FRIENDS_OF_URL % {author: @name}
        friends_of = parse_relationships(friends_of_uri)
        @friends_of = friends_of
      end

      def parse_subs_own
        subs_own_uri = ::Wagg::Constants::Author::SUBS_OWN_URL % {author: @name}
        subs_own = parse_subs(subs_own_uri)
        @subs_own = subs_own
      end

      def parse_subs_follow
        subs_follow_uri = ::Wagg::Constants::Author::SUBS_FOLLOW_URL % {author: @name}
        subs_follow = parse_subs(subs_follow_uri)
        @subs_follow = subs_follow
      end

      def parse_notes
        raise 'Not implemented yet.'
      end

      def parse_relationships(uri)
        relationships_raw_data = get_data(uri)
        relationships_table_items = relationships_raw_data.css('div#container > section > div.contents-layout > div.contents-body')

        relationships = Hash.new
        if relationships_table_items.at_css('p.info').nil?
          # relationships_items = friends_table_items.search('.//div[contains(concat(' ", normalize-space(@class), " "), " friends-item ")]')
          relationships_items = relationships_table_items.css('div.friends-item')
          # We are friendly!!!
          relationships_items.each do |relationship|
            name_item = ::Wagg::Utils::Functions.text_at_xpath(relationship,'./a/@href')
            date_item = ::Wagg::Utils::Functions.text_at_xpath(relationship,'./a/@title')
            matched_name = name_item.match(/\A\/user\/(?<name>.+)\z/)
            name = matched_name[:name]
            matched_datetime = date_item.match(/\A#{name}\sdesde\s(?<date>.+)\z/)
            unless matched_datetime.nil?
              # Relationships of less than 24 hours don't show the date yet (hence they are of today)
              matched_time = matched_datetime[:date].match(/\A(?<time>\d{2}:\d{2}\sUTC)\z/)
              if matched_time.nil?
                date = DateTime.strptime(matched_datetime[:date], '%d-%m-%Y %H:%M %Z')
              else
                now = DateTime.now.new_offset # Current datetime in UTC
                date = DateTime.strptime(now.strftime('%d-%m-%Y') + ' ' + matched_time[:time], '%d-%m-%Y %H:%M %Z')
              end
            end
            relationships[name] = date
          end
        end

        relationships
      end

      def parse_subs(uri)
        subs_raw_data = get_data(uri)
        subs_table_items = subs_raw_data.css('div#container > section > div.contents-layout > div.contents-body')

        subs = []
        if subs_table_items.at_css('p.info').nil?
          # relationships_items = friends_table_items.search('.//div[contains(concat(" ", normalize-space(@class), " "), " friends-item ")]')
          subs_items = subs_table_items.css('table > tr > td.name')
          # We are friendly!!!
          subs_items.each do |sub|
            name = ::Wagg::Utils::Functions.text_at_xpath(sub,'./a/@href')
            # TODO Clean up sub name?
            subs << name
          end
        end

        subs
      end

      private :parse_relationships, :parse_subs

      def as_json(options = {})
        {
            type: self.class.name.downcase,
            timestamp: ::Wagg::Utils::Functions.timestamp_to_text(@snapshot_timestamp),
            name: @name,
            data: {
              id: @id,
                fullname: (!@fullname.nil? ? @fullname : nil),
                disabled: disabled,
                signup: ::Wagg::Utils::Functions.datetime_to_text(@signup),
                karma: @karma,
                entropy: (!@entropy.nil? ? @entropy : nil),
                ranking: @ranking,
                friends: ::Wagg::Utils::Functions.hash_str_datetime_to_json(@friends),
                friends_of: ::Wagg::Utils::Functions.hash_str_datetime_to_json(@friends_of),
                subs_own: @subs_own,
                subs_follow: @subs_follow,
            }
        }
      end

      def to_json(*options)
        as_json(*options)
      end

    end
  end
end