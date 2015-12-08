# encoding: utf-8

module Wagg
  module Utils
    module Constants
      SITE_URL = 'https://www.meneame.net'
      # Author URL query template
      AUTHOR_URL = SITE_URL + '/user/%{author}'
      # Comment's vote regular expression and URL query templates
      # author: DD/MM-HH:MM:SS karma: #
      COMMENT_RE = /(?<author>\w+):\s(?<timestamp>\d{1,2}\/\d{1,2}-\d{1,2}:\d{1,2}:\d{1,2})\skarma:\s(?<weight>-?\d+)/
      COMMENT_VOTES_QUERY_URL = SITE_URL + '/backend/get_c_v.php?id=%{id}&p=%{page}'
      COMMENT_URL = SITE_URL + '/c/%{comment}'
      COMMENT_CONTRIBUTION_LIFETIME = 30*24*60*60 # 30 days
      COMMENT_VOTES_LIFETIME = 30*24*60*60 # 30 days
      # News's vote regular expression and URL query templates
      # author: HH:MM TMZ valor: #
      # author: DD-MM-YYYY HH:MM TMZ valor: #
      NEWS_RE = /(?<author>.+):\s(?<timestamp>(\d{1,2}-\d{1,2}-\d{4}\s)?\d{1,2}:\d{1,2})\s([A-Z]+)\svalor:\s(?<weight>-?\d+)/
      NEWS_LOG_QUERY_URL = '%{url}/log'
      NEWS_VOTES_QUERY_URL = SITE_URL + '/backend/meneos.php?id=%{id}&p=%{page}'
      NEWS_STATUS_TYPE = { 'discarded' => 'mnm-discarded',
                           'queued' => 'mnm-queued',
                           'published' => 'mnm-published',
                         }
      # TODO Wagg::Utils::Constants::NEWS_STATUS_TYPE[Wagg::Utils::Constants::NEWS_STATUS_TYPE_KILLED => 01*24*60*60
      #      Tiempo que permanecen abiertos los comentarios en meneos descartados por abuso: 1 día
      NEWS_CONTRIBUTION_LIFETIME = { 'discarded' => 02*24*60*60,
                                     'queued'    => 10*24*60*60,
                                     'published' => 30*24*60*60
                                   }
      NEWS_VOTES_LIFETIME = 30*24*60*60 # 30 days
      NEWS_LOG_EVENT_DISCARD = -2
      NEWS_LOG_EVENT_DEPUBLISH = -1
      NEWS_LOG_EVENT_NEW = 0
      NEWS_LOG_EVENT_EDIT = 1
      NEWS_LOG_EVENT_PUBLISH = 2
      NEWS_LOG_EVENT = { "link_new"         => NEWS_LOG_EVENT_NEW,
                         "link_edit"        => NEWS_LOG_EVENT_EDIT,
                         "link_publish"     => NEWS_LOG_EVENT_PUBLISH,
                         "link_depublished" => NEWS_LOG_EVENT_DEPUBLISH,
                         "link_discard"     => NEWS_LOG_EVENT_DISCARD
                       }
      # Page URL query templates
      PAGE_URL = { 'published' => SITE_URL + '/?page=%{page}',
                   'queued'    => SITE_URL + '/queue?page=%{page}',
                   'discarded' => SITE_URL + '/queue?page=%{page}&meta=_discarded'

      }
      # Vote regular expression matching both votes for news and comments (Not perfect but rather accurate)
      VOTE_RE = /(?<author>.+):\s+(?<timestamp>((\d{1,2}(\/|-)\d{1,2})(-\d{4})?)?(\s|-)?\d{1,2}:\d{1,2}(:\d{1,2})?(\s[A-Z]+)?)(\s(?:valor|karma):\D*(?<weight>-?\d+))?/
      # News vote rates
      VOTE_NEWS             =  0
      VOTE_COMMENT          =  1
      VOTE_COMMENT_LIFETIME = 30*24*60*60 # 30 days
      VOTE_NEWS_UPRATE      =  0
      VOTE_NEWS_DOWNRATE_IR = -1
      VOTE_NEWS_DOWNRATE_AN = -2
      VOTE_NEWS_DOWNRATE_CA = -3
      VOTE_NEWS_DOWNRATE_SE = -4
      VOTE_NEWS_DOWNRATE_SP = -5
      VOTE_NEWS_DOWNRATE_DU = -6
      VOTE_NEWS_DOWNRATE_MI = -7
      VOTE_NEWS_DOWNRATE_ER = -8
      VOTE_NEWS_DOWNRATE_CP = -9
      VOTE_NEWS_DOWNRATE    = { "irrelevante"     => VOTE_NEWS_DOWNRATE_IR,
                                "antigua"         => VOTE_NEWS_DOWNRATE_AN,
                                "cansina"         => VOTE_NEWS_DOWNRATE_CA,
                                "sensacionalista" => VOTE_NEWS_DOWNRATE_SE,
                                "spam"            => VOTE_NEWS_DOWNRATE_SP,
                                "duplicada"       => VOTE_NEWS_DOWNRATE_DU,
                                "microblogging"   => VOTE_NEWS_DOWNRATE_MI,
                                "errónea"         => VOTE_NEWS_DOWNRATE_ER,
                                "copia/plagio"    => VOTE_NEWS_DOWNRATE_CP
                              }

      # Retrieval defaults delays
      RETRIEVAL_DELAY = { 'default'  => 10,
                          'page'     =>  3,
                          'news'     =>  5,
                          'comment'  =>  4,
                          'vote'     =>  3,
                          'author'   =>  3
                         }
      # Maximum number of pages that can be read at once (accounting for 200 news)
      MAX_PAGE_INTERVAL = 10
    end
  end
end
