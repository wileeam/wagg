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

      def initialize
        @agents = Hash.new
        self.agent('default', 10)
      end

      def agent(name='default', delay=10)
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