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

  def test_id_of_news
    id_extended_news = 'informe-policial-acusa-exsecretario-estado-hacienda-cinco'
    news = ::Wagg.news(id_extended_news)

    assert_equal(news.id, '3386902')
  end

  def test_get_something
    id_extended_news = 'pp-condecora-perros-policias-interior-perros-salvan-vidas-hagan'
    news = ::Wagg.news(id_extended_news)

    news
  end
  def test_get_page_published_news_summaries
    page_index = '1'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)

    page

  end

  def test_ing
    require 'mini_racer'

    context = MiniRacer::Context.new
    context.eval 'var k_coef = new Array(); k_coef[1600814405] = 1.00; k_coef[1600814404] = 1.50; k_coef[1600813805] = parseInt(362); //-->'
    a = context.eval 'Object.keys(k_coef);'
    b = context.eval 'Object.values(k_coef);'
    c = Hash[a.zip b]
    c
  end

  def test_get_news_comments
    id_extended_news = 'informe-policial-acusa-exsecretario-estado-hacienda-cinco'
    news = ::Wagg.news(id_extended_news, 'html')

    assert_equal(news.id, '3386902')
  end

  def test_get_hidden_comment
    id_extended_news = 'nombres-102-000-victimas-franquismo-extremadura-andalucia-norte'
    index_hidden_comment = 1
    news = ::Wagg.news(id_extended_news, 'html')

    expected_hidden_body = '<p>¡A ver! ... ¡de prisa un "Paracuellos" en Andalucia! ... o el trifachito andaluz se va a poner nervioso. </p>'
    actual_hidden_body = news.comments[index_hidden_comment].body

    assert_equal(actual_hidden_body, expected_hidden_body)
  end


end