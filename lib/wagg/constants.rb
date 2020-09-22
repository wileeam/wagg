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
      # TODO: Do me
    end

    # Vote URL query templates
    module Vote
      # TODO: Do me
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
      RETRIEVAL_DELAY = { RETRIEVAL_TYPE['default'] => 10,
                          RETRIEVAL_TYPE['page'] => 3,
                          RETRIEVAL_TYPE['news'] => 5,
                          RETRIEVAL_TYPE['comment'] => 4,
                          RETRIEVAL_TYPE['vote'] => 3,
                          RETRIEVAL_TYPE['author'] => 3 }.freeze
    end
  end
end
