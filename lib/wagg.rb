# encoding: UTF-8

require 'yaml'

require 'wagg/version'

require 'wagg/utils/retriever'

require_relative 'wagg/crawler/author'
require_relative 'wagg/crawler/news'
require_relative 'wagg/crawler/comment'
require_relative 'wagg/crawler/page'

module Wagg
  #class Error < StandardError; end
  # Your code goes here...
  class << self
    def author(name)
      Crawler::Author.parse(name)
    end

    def page(index, type)
      Crawler::Page.parse(index, type)
    end

    def news(id_extended, comments_mode = 'rss')
      Crawler::News.parse(id_extended, comments_mode)
    end

    def comment(id)
      false
    end

    def votes(id, type='news')
      false
    end

    def settings
      Settings.configuration
    end
  end

  module Settings
    class << self
      attr_accessor :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def self.reset
      self.configuration = Configuration.new
    end

    class Configuration
      attr_accessor :credentials
      attr_accessor :user_agent
      attr_accessor :user_agent_log

      def initialize
        @credentials = Hash.new
        @credentials['username'] = nil
        @credentials['password'] = nil

        secrets_path = ::Wagg::Constants::Retriever::CREDENTIALS_PATH
        if File.file?(secrets_path)
          credentials_yaml = YAML.load(File.read(secrets_path))

          @credentials['username'] = credentials_yaml['username']
          @credentials['password'] = credentials_yaml['password']
        end

        @user_agent = 'Mac Mozilla'
        @user_agent_log = false
        @user_agent_logpath = 'mechanize_agent.log'
      end

      # def credentials?
      #   if @credentials.key?("username") && @credentials.key?("password")
      #     if !@credentials.key?("username").nil? && !@credentials.key?("password").nil?
      #       return !@credentials.key?("username").empty? && !@credentials.key?("password").empty?
      #     end
      #   end
      #
      #   return FALSE
      # end
    end

  end
end
