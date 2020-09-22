# encoding: UTF-8

require "test_helper"

require "wagg/utils/retriever"

class Retriever < MiniTest::Test
  def setup
    @retriever = ::Wagg::Utils::Retriever.instance
    # @credentials = ::Wagg::Settings.configuration.credentials
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

  def test_get_id_author
    id_author = 'neotobarra2'
    author = ::Wagg.author(id_author)

    assert_equal(author.id, '292897')
  end

  def test_get_enabled_author_page
    enabled_author = 'didacgil9'
    author = ::Wagg.author(enabled_author)

    assert_equal(author.name, enabled_author)
    assert(!author.disabled)
  end

  def test_get_disabled_author_page
    disabled_author = '--334312--'
    author = ::Wagg.author(disabled_author)

    assert_equal(author.name, disabled_author)
    assert(author.disabled)
  end

  def test_get_relationships_author_page
    relationships_author = 'pinaveta'
    author = ::Wagg.author(relationships_author)

    assert_operator(author.friends.length, '>=', 20)
    assert_operator(author.friends_of.length, '>=', 25)
  end


  def test_get_subs_author_page
    subs_author = 'Condetino'
    author = ::Wagg.author(subs_author)

    assert_equal(author.subs_own.length, 0)
    assert_equal(author.subs_follow.length, 2)
  end

  def test_get_author_json
    json_author = 'Gerardo_Diaz_Finetti'
    author = ::Wagg.author(json_author)

    json = author.to_json().to_s
  end

end