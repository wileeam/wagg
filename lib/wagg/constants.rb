# frozen_string_literal: true

module Wagg
  module Constants
    module Site
      MAIN_URL = 'https://www.meneame.net'
      LOGIN_URL = File.join("#{MAIN_URL}/login")
    end

    # Author URL query templates
    module Author
      MAIN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, '/user/', '%{author}')
      PROFILE_URL = File.join(MAIN_URL, '/profile')
      FRIENDS_URL = File.join(MAIN_URL, '/friends')
      FRIENDS_OF_URL = File.join(MAIN_URL, '/friend_of')
      SUBS_OWN_URL = File.join(MAIN_URL, '/subs')
      SUBS_FOLLOW_URL = File.join(MAIN_URL, '/subs_follow')
      HISTORY_URL = File.join(MAIN_URL, '/history')

      AVATAR_REGEX = %r{\Ahttps:/{2}mnmstatic\.net/cache/\d{2}/[[:alnum:]]{2}/(?<id>\d+)-(?<timestamp>\d+)-\d{2}\.jpg\z}.freeze
      DISABLED_REGEX = /\A-{2}(?<id>\d+)-{2}\z/.freeze
    end

    # Comment URL query templates
    module Comment
      MAIN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/c/', '%{id}'])
      HIDDEN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/backend/', 'get_comment.php?id=%{id}'])

      VOTES_QUERY_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/backend/', 'get_c_v.php?id=%{id}&p=%{page}'])

      STATUS_TYPE = { 'created' => 'created',
                      'edited' => 'edited' }.freeze
    end

    # News URL query templates
    module News
      MAIN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/story/', '%{id_extended}'])
      MAIN_PERMALINK_URL = File.join('http://menea.me', %(permalink_id))
      LOG_URL = File.join(MAIN_URL, '/log')
      KARMA_STORY_JSON_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/backend/', 'karma-story.json?id=%{id}'])

      COMMENTS_URL = File.join(MAIN_URL, ['/standard/', '%{page}'])
      COMMENTS_URL_MAX_PAGE = 100
      COMMENTS_RSS_URL = File.join(::Wagg::Constants::Site::MAIN_URL, '/comments_rss?id=%{id}')

      VOTES_QUERY_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/backend/', 'meneos.php?id=%{id}&p=%{page}'])

      STATUS_TYPE = { 'discarded' => 'discarded'.downcase,
                      'sent' => 'sent'.downcase,
                      'queued' => 'queued'.downcase,
                      'candidate' => 'candidate'.downcase,
                      'published' => 'published'.downcase }.freeze

      EVENT_LOG_TYPE = { 'link_discard' => -2,
                         'link_depublished' => -1,
                         'link_new' => 0,
                         'link_edit' => 1,
                         'link_publish' => 2 }.freeze

      CATEGORY_TYPE = { 'actualidad' => 'actualidad',
                        'articles' => 'Artículos' }.freeze
    end

    module Page
      # Page URL query templates
      MAIN_URL = { ::Wagg::Constants::News::STATUS_TYPE['published'] => File.join(::Wagg::Constants::Site::MAIN_URL, '/?page=%{page}'),
                   ::Wagg::Constants::News::STATUS_TYPE['queued'] => File.join(::Wagg::Constants::Site::MAIN_URL,
                                                                               '/queue?page=%{page}'),
                   ::Wagg::Constants::News::STATUS_TYPE['candidate'] => File.join(::Wagg::Constants::Site::MAIN_URL,
                                                                                  '/queue?page=%{page}&meta=_popular'),
                   ::Wagg::Constants::News::STATUS_TYPE['discarded'] => File.join(::Wagg::Constants::Site::MAIN_URL,
                                                                                  '/queue?page=%{page}&meta=_discarded') }.freeze

      MAX_SUMMARIES = 25
    end

    module Tag
      NAME_REGEX = %r{\A/search\?p=tags&q=\+?(?<tag>.+)\z}.freeze
    end

    # Vote URL query templates
    module Vote
      TYPE = { 'news' => 'news',
               'comment' => 'comment' }.freeze

      NEWS_LIFETIME = 30 * 24 * 60 * 60 # 30 days
      COMMENT_LIFETIME = 30 * 24 * 60 * 60 # 30 days

      NEWS_REGEX = /\A(?<author>.+):[[:space:]](?:(?<datetime>\d{2}-\d{2}-\d{4}[[:space:]]\d{2}:\d{2}[[:space:]]UTC)|(?<time>\d{2}:\d{2}[[:space:]]UTC))(?:[[:space:]]valor:[[:space:]](?<weight>\d{1,2}))?\z/.freeze
      COMMENT_REGEX = %r{\A(?<author>.+):[[:space:]](?<datetime>\d{2}/\d{2}-\d{2}:\d{2}:\d{2})[[:space:]]karma:[[:space:]](?<weight>-?\d{1,2})\z}.freeze

      SIGN = { 'positive' => 'positive',
               'negative' => 'negative' }.freeze

      NEWS_SIGN = SIGN
      NEWS_NEGATIVE_WEIGHT = { 'antigua' => -2,
                               'bulo' => -10,
                               'cansina' => -3,
                               'copia/plagio' => -9,
                               'duplicada' => -6,
                               'errónea' => -8,
                               'irrelevante' => -1,
                               'microblogging' => -7,
                               'muro de pago' => -11,
                               'sensacionalista' => -4,
                               'spam' => -5 }.freeze

      COMMENT_SIGN = SIGN
    end

    module Retriever
      CREDENTIALS_PATH = File.join('config', 'secrets.yml')
      AGENT_COOKIES_PATH = 'config/cookies'
      AGENT_COOKIE = File.join(::Wagg::Constants::Retriever::AGENT_COOKIES_PATH, 'cookie_agent_%{name}.yml')

      AGENT_TYPE = { 'default' => 'default'.downcase,
                     'page' => 'page'.downcase,
                     'news' => 'news'.downcase,
                     'comment' => 'comment'.downcase,
                     'vote' => 'vote'.downcase,
                     'author' => 'author'.downcase }.freeze
      # Retrieval defaults delays (in seconds)
      AGENT_OPTIONS = {
        ::Wagg::Constants::Retriever::AGENT_TYPE['default'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 10,
          'log' => false
        },
        ::Wagg::Constants::Retriever::AGENT_TYPE['page'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 3,
          'log' => false
        },
        ::Wagg::Constants::Retriever::AGENT_TYPE['news'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 4,
          'log' => false
        },
        ::Wagg::Constants::Retriever::AGENT_TYPE['comment'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 5,
          'log' => false
        },
        ::Wagg::Constants::Retriever::AGENT_TYPE['vote'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 3,
          'log' => false
        },
        ::Wagg::Constants::Retriever::AGENT_TYPE['author'] => {
          'alias' => 'Mac Mozilla',
          # 'tor_proxy' => ['localhost', 9050, 9051],
          # 'delay' => 3,
          'log' => false
        },
      }.freeze
      AGENT_LOGS_PATH = 'logs'
      AGENT_LOG = File.join(::Wagg::Constants::Retriever::AGENT_LOGS_PATH, 'log_agent_%{name}.log')

      # Maximum number of pages that can be read at once (accounting for 200 news)
      MAX_PAGE_INTERVAL = 10
    end
  end
end
