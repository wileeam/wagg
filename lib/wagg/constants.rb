module Wagg
  module Constants
    module Site
      MAIN_URL = 'https://www.meneame.net'
      LOGIN_URL = File.join(MAIN_URL + '/login')
    end

    # Author URL query templates
    module Author
      MAIN_URL = File.join(::Wagg::Constants::Site::MAIN_URL, "/user/", "%{author}")
      PROFILE_URL = File.join(MAIN_URL, "/profile")
      HISTORY_URL = File.join(MAIN_URL, "/history")
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
  end
end
