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

end