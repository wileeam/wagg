# encoding: UTF-8

module Wagg
  module Constants
    module Site
      MAIN_URL = 'https://www.meneame.net'
      LOGIN_URL = File.join(MAIN_URL + '/login')
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
    end

    # Comment URL query templates
    module Comment
      # TODO: Do me
    end

    # News URL query templates
    module News
      MAIN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, ['/story/', '%{id_extended}'])
      LOG_URL = File.join(MAIN_URL, '/log')
      #NEWS_COMMENTS_RSS_URL = SITE_URL + '/comments_rss?id=%{id}'

      STATUS_TYPE = { 'discarded' => 'discarded',
                      'sent' => 'sent',
                      'queued' => 'queued',
                      'candidate' => 'candidate',
                      'published' => 'published' }.freeze

      EVENT_LOG_TYPE = { 'link_discard' => -2,
                         'link_depublished' => -1,
                         'link_new' => 0,
                         'link_edit' => 1,
                         'link_publish' => 2 }.freeze
    end

    module Page
      # Page URL query templates
      MAIN_URL = { ::Wagg::Constants::News::STATUS_TYPE['published'] => File.join(::Wagg::Constants::Site::MAIN_URL, '/?page=%{page}'),
                   ::Wagg::Constants::News::STATUS_TYPE['queued'] => File.join(::Wagg::Constants::Site::MAIN_URL, '/queue?page=%{page}'),
                   ::Wagg::Constants::News::STATUS_TYPE['candidate'] => File.join(::Wagg::Constants::Site::MAIN_URL, '/queue?page=%{page}&meta=_popular'),
                   ::Wagg::Constants::News::STATUS_TYPE['discarded'] => File.join(::Wagg::Constants::Site::MAIN_URL, '/queue?page=%{page}&meta=_discarded')}.freeze
    end
    # Vote URL query templates
    module Vote
      NEWS_LIFETIME = 30*24*60*60 # 30 days
      COMMENT_LIFETIME = 30*24*60*60 # 30 days
    end


    module Retriever
      CREDENTIALS_PATH = 'config/secrets.yml'
      COOKIES_PATH = 'config/cookies.yml'

      RETRIEVAL_TYPE = { 'default' => 'default',
                         'page' => 'page',
                         'news' => 'news',
                         'comment' => 'comment',
                         'vote' => 'vote',
                         'author' => 'author' }.freeze
      # Retrieval defaults delays (in seconds)
      RETRIEVAL_DELAY = { ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['default'] => 10,
                          ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['page'] => 3,
                          ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['news'] => 5,
                          ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['comment'] => 4,
                          ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['vote'] => 3,
                          ::Wagg::Constants::Retriever::RETRIEVAL_TYPE['author'] => 3 }.freeze

      # Maximum number of pages that can be read at once (accounting for 200 news)
      MAX_PAGE_INTERVAL = 10
    end
  end
end