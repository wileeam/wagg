# encoding: utf-8

require 'singleton'
require 'mechanize'

require 'wagg/utils/constants'
require 'wagg/utils/functions'
require 'wagg'

module Wagg
  module Utils
    # Singleton for Mechanize
    class Retriever
      include Singleton

      attr_reader :agents
      attr_reader :configuration

      def initialize
        @agents = Hash.new
        @configuration = Wagg.configure
        #self.agent('default', Wagg::Utils::Constants::RETRIEVAL_DELAY['default'])
        self.agent('default', Wagg.configuration.retrieval_delay['default'])
      end

      #def agent(name='default', delay=Wagg::Utils::Constants::RETRIEVAL_DELAY['default'])
      def agent(name='default', delay=Wagg.configuration.retrieval_delay['default'])
        if @agents[name].nil?
          custom_agent = Mechanize.new
          custom_agent.pre_connect_hooks << lambda do |custom_agent, request|
            sleep delay
          end
          @agents[name] = custom_agent
        end

        @agents[name]
      end

      def get(url, agent_name='default')
        #@agents[agent_name].get(url)
        agent = self.agent(agent_name)
        agent.get(url)
      end
    end
  end
end