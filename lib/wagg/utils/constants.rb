# encoding: utf-8

module Wagg
  module Utils
    module Constants
      SITE_URL = 'https://www.meneame.net'
      # Comment's vote regular expression and URL query templates
      # author: DD/MM-HH:MM:SS karma: #
      COMMENT_RE = /(?<author>\w+):\s(?<timestamp>\d{1,2}\/\d{1,2}-\d{1,2}:\d{1,2}:\d{1,2})\skarma:\s(?<weight>-?\d+)/
      COMMENT_VOTES_QUERY_URL = 'https://www.meneame.net/backend/get_c_v.php?id=%{id}&p=%{page}'
      COMMENT_URL = 'https://www.meneame.net/c/%{comment}'
      # News's vote regular expression and URL query templates
      # author: HH:MM TMZ valor: #
      # author: DD-MM-YYYY HH:MM TMZ valor: #
      NEWS_RE = /(?<author>.+):\s(?<timestamp>(\d{1,2}-\d{1,2}-\d{4}\s)?\d{1,2}:\d{1,2})\s([A-Z]+)\svalor:\s(?<weight>-?\d+)/
      NEWS_VOTES_QUERY_URL = 'https://www.meneame.net/backend/meneos.php?id=%{id}&p=%{page}'
      # Page URL query templates
      PAGE_URL = 'https://www.meneame.net/?page=%{page}'
      # Vote regular expression matching both votes for news and comments (Not perfect but rather accurate)
      VOTE_RE = /(?<author>.+):\s+(?<timestamp>((\d{1,2}(\/|-)\d{1,2})(-\d{4})?)?(\s|-)?\d{1,2}:\d{1,2}(:\d{1,2})?(\s[A-Z]+)?)(\s(?:valor|karma):\D*(?<weight>-?\d+))?/
      # News vote rates
      VOTE_NEWS             =  0
      VOTE_COMMENT          =  1
      VOTE_NEWS_LIFETIME    = 2592000 # 30 days
      VOTE_COMMENT_LIFETIME = 2592000 # 30 days (note that )
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
    end
  end
end
