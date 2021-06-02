# encoding: utf-8

require "test_helper"

class NewsTest < MiniTest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_get_id_of_news
    id_extended_news = 'paso-cuando-dejaste-tragar-tu-trabajo-cuenta-tu-caso'
    news = ::Wagg.news(id_extended_news)

    assert(news.id, '3392421')
  end

  def test_get_story_of_news_events
    id_extended_news = 'marruecos-anunciara-proximas-horas-ruptura-relaciones-espana'
    #id_extended_news = 'sitios-interesantes-google-maps'
    news = ::Wagg.news(id_extended_news)

    news.karma_events
    # TODO(guillermo): do me!

  end

  def test_get_category_of_article_news
    #id_extended_article_category_news = 'motivo-cual-entrais-meneame'
    id_extended_article_category_news = 'golpe-chile-richard-nixon-hay-forma-desbancar-allende-mejor'
    news = ::Wagg.news(id_extended_article_category_news)

    news
  end

  def test_get_summary_of_news
    page_index = '2'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)
    news_summary = page.news_list.first

    expected_news = ::Wagg::Crawler::News.from_summary(news_summary)
    actual_news = ::Wagg.news(news_summary.id_extended)

    expected_news_id = expected_news.id
    actual_news_id = actual_news.id

    assert_equal(expected_news_id, actual_news_id)
  end

  def test_get_tags_of_news
    id_extended_news = 'pp-pide-hbo-retire-cartel-patria-equipara-victimas-verdugos'
    news = ::Wagg.news(id_extended_news)

    expected_tags = %w[pp patria ofensa víctimas verdugos hbo retirada].map { |tag| tag.unicode_normalize(:nfkc)}
    actual_tags = news.tags

    assert_equal(expected_tags.length, actual_tags.length)
    assert(expected_tags.sort == actual_tags.sort)
  end

  def test_to_json_from_json
    random_news = 'asi-como-soldados-chinos-montan-menos-30-minutos-puente-mas'
    news = ::Wagg.news(random_news)

    expected_news_json = news.to_json

    actual_news = ::Wagg::Crawler::News.from_json(expected_news_json)
    actual_news_json = actual_news.to_json

    assert_equal(expected_news_json, actual_news_json)
  end

end