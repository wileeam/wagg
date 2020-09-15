require "test_helper"

require "wagg/utils/retriever"

class Retriever < MiniTest::Test
  def setup
    @retriever = ::Wagg::Utils::Retriever.instance
    @credentials = ::Wagg::Settings.configuration.credentials
    #Wagg::Settings.configure do |config|
    #  config.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.30 Safari/537.36"
    #end
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_get_login_page
    r = @retriever.login(@credentials)
    #c = r.cookie_jar
    assert_equal(r.code, "200")
  end


end