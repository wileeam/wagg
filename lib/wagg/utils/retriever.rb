# encoding: utf-8

require 'singleton'
require 'mechanize'

require 'wagg/utils/constants'
require 'wagg/utils/functions'

module Wagg
  module Utils
    # Singleton for Mechanize
    class Retriever
      include Singleton

      attr_reader :agents
      attr_reader :configuration

      def initialize
        @agents = Hash.new
        @cookie_jar = nil
        @configuration = Wagg.configure
        self.agent('default', Wagg.configuration.retrieval_delay['default'])
      end

      def agent(name='default', delay=Wagg.configuration.retrieval_delay[name])

        if @agents[name].nil?
          custom_agent = Mechanize.new

          if name == 'default'
            @agents[name] = custom_agent

            unless Wagg.configuration.retrieval_credentials['username'].nil? || Wagg.configuration.retrieval_credentials['password'].nil?
              login(Wagg.configuration.retrieval_credentials['username'].to_s, Wagg.configuration.retrieval_credentials['password'].to_s)
              # TODO Add cookie only if login is successful otherwise, do not replace cookie
              #if login_successful
                @cookie_jar = @agents[name].cookie_jar
              #end
            end
          end

          custom_agent.pre_connect_hooks << lambda do |custom_agent, request|
            sleep delay
          end

          unless @cookie_jar.nil?
            custom_agent.cookie_jar = @cookie_jar
          end

          @agents[name] = custom_agent
        end

        @agents[name]
      end

      def get(url, agent_name='default')
        unless @cookie_jar.nil?
          self.agent(agent_name).cookie_jar = @cookie_jar
        end

        # TODO Handle when Mechanize::ResponseCodeError
        #begin
          content = self.agent(agent_name).get(url)
        #rescue Mechanize::ResponseCodeError => response_error
          #puts response_error.response_code
          #puts response_error.page
          #content = response_error.page
        #end

        unless @cookie_jar.nil?
          @cookie_jar = self.agent(agent_name).cookie_jar
        end

        content
      end

      def login(user=nil, password=nil)
        puts 'logging in'
        puts @agents['default'].cookie_jar.jar
        login_page = self.get(Wagg::Utils::Constants::LOGIN_URL)
        login_form_item = login_page.form_with(:action => Wagg::Utils::Constants::LOGIN_URL)

        user_form_item = login_form_item.field_with(:name => 'username')
        password_form_item = login_form_item.field_with(:name => 'password')

        user_form_item.value = user
        password_form_item.value = password

        login_form_item.submit
        puts @agents['default'].cookie_jar.jar
      end

      private :login

    end
  end
end