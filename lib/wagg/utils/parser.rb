# frozen_string_literal: true

require 'feedjira'

# Inspired by https://gist.github.com/mertonium/11087612
module Feedjira
  module Parser
    # It's good practice to namespace your parsers, so we'll put
    # this one in the Versa namespace.
    module Wagg
      class CommentsEntry
        include SAXMachine
        include Feedjira::FeedEntryUtilities

        # Declare the fields we want to parse out of the XML feed.
        element :title, as: :comment_title
        element :link, as: :comment_url
        element 'meneame:url', as: :news_url
        element 'meneame:comment_id', as: :comment_id
        element 'meneame:link_id', as: :news_id
        element 'meneame:order', as: :index
        element 'meneame:user', as: :author
        element 'meneame:votes', as: :num_votes
        element 'meneame:karma', as: :karma
        element :pubDate, as: :published
        element :description, as: :body

        element :guid, as: :entry_id

        # We remove the query string from the url by overriding the 'url' method
        # originally defined by including FeedEntryUtilities in our class.
        # (see https://github.com/feedjira/feedjira/blob/master/lib/feedjira/feed_entry_utilities.rb)
        def url
          @url = @url.gsub(/\?.*$/, '')
        end
      end

      class CommentsList
        include SAXMachine
        include Feedjira::FeedUtilities

        # Define the fields we want to parse using SAX Machine declarations
        element :title
        element :link, as: :site_url
        element :description, as: :site_description
        element :pubDate, as: :published
        element :language

        # Parse all the <item>s in the feed with the class we just defined above
        elements :item, as: :entries, class: CommentsEntry

        attr_accessor :feed_url

        # This method is required by all Feedjira parsers. To decide which
        # parser to use, Feedjira cycles through each parser it knows about
        # and passes the first 2000 characters of the feed to this method.
        #
        # To make sure your parser is only used when it's supposed to be used,
        # test for something unique in those first 2000 characters. URLs seem
        # to be a good choice.
        #
        # This parser, for example, is looking for an occurrence of
        # '<link>http://www.meneame.net' which we should
        # only really find in the feed we are targeting.
        def self.able_to_parse?(xml)
          (%r{<link>http://www\.meneame\.net/} =~ xml)
        end
      end
    end
  end
end
