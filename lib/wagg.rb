# frozen_string_literal: true

require 'logger'
require 'yaml'

require 'wagg/version'

require 'wagg/utils/retriever'

require_relative 'wagg/crawler/author'
require_relative 'wagg/crawler/news'
require_relative 'wagg/crawler/news_summary'
require_relative 'wagg/crawler/comment'
require_relative 'wagg/crawler/page'

module Wagg
  # class Error < StandardError; end

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

    def comment(_id)
      false
    end

    def votes(_id, _type = 'news')
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

      def initialize
        @credentials = {'username' => nil, 'password' => nil}

        secrets_path = ::Wagg::Constants::Retriever::CREDENTIALS_PATH
        if File.file?(secrets_path)
          credentials_yaml = YAML.safe_load(File.read(secrets_path))

          @credentials['username'] = credentials_yaml['username']
          @credentials['password'] = credentials_yaml['password']
        end
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

  class Logging
    def self.log
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
      end

      @logger
    end
  end

end
