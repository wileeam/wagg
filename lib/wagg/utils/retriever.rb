# encoding: UTF-8

require 'singleton'
require 'mechanize'
require 'logger'

require 'wagg/constants'

module Wagg
  module Utils
    # Singleton for Mechanize
    class Retriever
      include Singleton

      attr_reader :agents

      def initialize
        @agents = {}
        #@cookie_jar = nil

        #self.agent('default')
      end
      
      def agent(name='default')
        if @agents[name].nil?
          custom_agent = setup()

          if name.eql? 'default'
            @agents[name] = custom_agent
            login(@agents[name], ::Wagg::Settings.configuration.credentials)
          end

          # custom_agent.pre_connect_hooks << lambda do |custom_agent, request|
          #   sleep Wagg.configuration.retrieval_delay[name]
          # end

          #custom_agent.cookie_jar = @cookie_jar unless @cookie_jar.nil?

          @agents[name] = custom_agent
        end

        @agents[name]
      end

      def get_agent(name)
        agent(name)
      end
      
      def get_content(data, content_type='default')

        case content_type
        when 'author'
          get_author(data)
        when 'comment'
        when 'news'
        when 'vote'
          # Need cookie
        else # 'default'
             # Don't need cookie
        end
        content = agent

        agent(agent_name).cookie_jar = @cookie_jar unless @cookie_jar.nil?

        # TODO: Handle when Mechanize::ResponseCodeError
        #begin
        content = agent(agent_name).get(url)
        #rescue Mechanize::ResponseCodeError => response_error
        #puts response_error.response_code
        #puts response_error.page
        #content = response_error.page
        #end

        @cookie_jar = agent(agent_name).cookie_jar unless @cookie_jar.nil?

        content
      end

      def get_author(name)
        agent = get_agent('author')
        profile_uri = ::Wagg::Constants::Author::PROFILE_URL % {author:name}
        content = agent.get profile_uri
        #content.encoding = 'utf-8'

        content
      end
      

      def setup(name='default')
        agent = Mechanize.new
        agent.user_agent_alias = ::Wagg::Settings.configuration.user_agent
        if ::Wagg::Settings.configuration.user_agent_log
          # TODO: Add name parameter to logpath somewhere
          agent.log = Logger.new ::Wagg::Settings.configuration.user_agent_logpath
        end

        agent
      end

      def login(agent, credentials=nil)
        cookies_path = ::Wagg::Constants::Retriever::COOKIES_PATH

        # if credentials.nil? && File.file?(cookies_path)
        if File.file?(cookies_path)
          agent.cookie_jar.load(cookies_path)
        else
          login_uri = ::Wagg::Constants::Site::LOGIN_URL

          unless credentials.nil?
            login_page = agent.get login_uri

            login_form_item = login_page.form_with(action: login_uri)

            login_form_item.field_with(name: 'username').value = credentials['username']
            login_form_item.field_with(name: 'password').value = credentials['password']

            agent.submit login_form_item

            # TODO: Add cookie only when login is successful else don't replace cookie
            agent.cookie_jar.save(cookies_path, session: true)
          end
        end

      end

      private :login, :setup

    end
  end
end

