# frozen_string_literal: true
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
          custom_agent = Mechanize.new

          if name.eql?'default'
            @agents[name] = custom_agent

            #Wagg::Settings.configuration.credentials?

            unless Wagg::Settings.configuration.credentials['username'].nil? || Wagg::Settings.configuration.credentials['password'].nil?
              login(Wagg.configuration.retrieval_credentials['username'].to_s, Wagg.configuration.retrieval_credentials['password'].to_s)
              # TODO: Add cookie only if login is successful otherwise, do not replace cookie
              #if login_successful
              @cookie_jar = @agents[name].cookie_jar
              #end
            end
          end

          custom_agent.pre_connect_hooks << lambda do |custom_agent, request|
            sleep Wagg.configuration.retrieval_delay[name]
          end

          custom_agent.cookie_jar = @cookie_jar unless @cookie_jar.nil?

          @agents[name] = custom_agent
        end

        @agents[name]
      end

      def get_content(uri, content_type='default')

        case content_type
        when 'author'
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

      def get_agent(cookie)
        # https://avdi.codes/preserving-session-with-mechanize/
      end

      def setup_agent
        agent = Mechanize.new
        agent.log = Logger.new ::Wagg::Settings.configuration.user_agent_log
        agent.user_agent_alias = ::Wagg::Settings.configuration.user_agent

        agent
      end

      def login(credentials=nil, uri=::Wagg::Constants::Site::LOGIN_URL)

        unless credentials.nil?
          login_page = agent.get uri

          login_form_item = login_page.form_with(action: uri)

          login_form_item.field_with(name: 'username').value = credentials['username']
          login_form_item.field_with(name: 'password').value = credentials['password']

          agent.submit login_form_item
        end
      end

      # private :login, :setup_agent

    end
  end
end

