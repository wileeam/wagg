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

  def test_get_author_json
    json_author = 'Gerardo_Diaz_Finetti'
    author = ::Wagg.author(json_author)

    json = author.to_json().to_s
  end

  def test_get_page_published_news_summaries
    page_index = '1'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)

    page

  end

  def test_get_news_comments
    id_extended_news = 'informe-policial-acusa-exsecretario-estado-hacienda-cinco'
    news = ::Wagg.news(id_extended_news, 'html')

    assert_equal(news.id, '3386902')
  end
end