# frozen_string_literal: true

require 'singleton'
require 'mechanize'
require 'tor'
require 'socksify'

require 'wagg/constants'

module Wagg
  module Utils
    # Singleton for Mechanize
    class Retriever
      include Singleton

      attr_reader :agents

      def initialize
        @agents = {}
        # @cookie_jar = nil

        # self.agent('default')
      end

      def agent(name = 'default')
        if @agents[name].nil?
          if name.eql? 'default'
            @agents[name] = Agent.new(name, true)
          else
            credentials = ::Wagg::Settings.configuration.credentials
            @agents[name] = Agent.new(name, false, credentials)
          end
        end

        @agents[name]
      end

      def get(uri, name = 'default', disable_proxy = true)
        agent = self.agent(name)

        agent.get(uri, disable_proxy)
        # page.encoding = 'utf-8'
        # page.body.force_encoding('utf-8')
      end

      def get_content(data, content_type = 'default')
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
        # begin
        content = agent(agent_name).get(url)
        # rescue Mechanize::ResponseCodeError => response_error
        # puts response_error.response_code
        # puts response_error.page
        # content = response_error.page
        # end

        @cookie_jar = agent(agent_name).cookie_jar unless @cookie_jar.nil?

        content
      end

      class Agent
        attr_reader :agent, :name, :tor_proxy

        def initialize(name = 'default', anonymous = true, credentials = nil)
          @name = ::Wagg::Constants::Retriever::AGENT_TYPE.value?(name) ? name : ::Wagg::Constants::Retriever::AGENT_TYPE['default']

          @agent = setup(@name, ::Wagg::Constants::Retriever::AGENT_OPTIONS[@name])

          login(credentials, true) unless anonymous
        end

        def get(uri, disable_proxy = true)
          data = nil
          referer = ::Wagg::Constants::Site::MAIN_URL

          ::Wagg::Logging.log.info("Agent '#{@name}' retrieving URI: #{uri}.")
          # Checking for @tor_proxy.nil? is a safeguard in case the are no defaults regardless of the wish
          if !disable_proxy && !@tor_proxy.nil?
            Socksify.proxy(@tor_proxy['host'], @tor_proxy['port-data']) do
              data = @agent.get(uri, parameters = [], referer = referer)
            end
            if @tor_proxy.key?('port-control')
              Tor::Controller.connect(host: @tor_proxy['host'], port: @tor_proxy['port-control']) do |tor|
                # send NEWNYM signal (gets new IP)
                tor.signal('NEWNYM')
              end
            end
          else
            data = @agent.get(uri, parameters = [], referer = referer)
          end

          data
        end

        def setup(name = 'default', options = {})
          agent = Mechanize.new

          if options.has_key?('alias')
            # See https://www.rubydoc.info/gems/mechanize/Mechanize for a list of AGENT_ALIASES
            agent.user_agent_alias = options['alias']
          end

          if options.has_key?('tor_proxy')
            @tor_proxy = {
              'host' => options['tor_proxy'][0],
              'port-data' => options['tor_proxy'][1]
            }
            @tor_proxy['port-control'] = options['tor_proxy'][2] if options['tor_proxy'].length == 3
          end

          if options.has_key?('delay')
            agent.pre_connect_hooks << lambda do |_a, _r|
              sleep options['delay']
            end
          end

          if options.has_key?('log') && options['log']
            log_path = format(::Wagg::Constants::Retriever::AGENT_LOG, name: name)
            unless File.directory?(::Wagg::Constants::Retriever::AGENT_LOGS_PATH)
              FileUtils.mkdir_p(::Wagg::Constants::Retriever::AGENT_LOGS_PATH)
            end

            agent.log = Logger.new(log_path)
          end

          agent
        end

        def login(credentials = nil, save_cookie = true)
          cookies_path = format(::Wagg::Constants::Retriever::AGENT_COOKIE, name: @name)

          # Always check for a saved cookie... it may save some 403s
          if File.file?(cookies_path)
            @agent.cookie_jar.load(cookies_path)
          elsif credentials
            login_uri = ::Wagg::Constants::Site::LOGIN_URL

            login_page = get(login_uri, true)
            login_form_item = login_page.form_with(action: login_uri)
            login_form_item.field_with(name: 'username').value = credentials['username']
            login_form_item.field_with(name: 'password').value = credentials['password']

            @agent.submit(login_form_item)

            if save_cookie
              # TODO: Save cookie only when login is successful else don't replace cookie
              unless File.directory?(::Wagg::Constants::Retriever::AGENT_COOKIES_PATH)
                FileUtils.mkdir_p(::Wagg::Constants::Retriever::AGENT_COOKIES_PATH)
              end

              @agent.cookie_jar.save(cookies_path, session: true)
            end
          else
            # TODO(guillermo): Consider logging rather than raising an exception
            raise("Couldn't login neither from credentials nor from cookies")
          end
        end

        private :login, :setup
      end
    end
  end
end
