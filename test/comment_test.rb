# frozen_string_literal: true

require 'test_helper'

class CommentTest < MiniTest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_get_hidden_comment
    id_extended_news = 'nombres-102-000-victimas-franquismo-extremadura-andalucia-norte'
    index_hidden_comment = 1
    news = ::Wagg.news(id_extended_news, 'html')

    expected_hidden_body = '<p>¡A ver! ... ¡de prisa un "Paracuellos" en Andalucia! ... o el trifachito andaluz se va a poner nervioso. </p>'
    actual_hidden_body = news.comments.as_hash[index_hidden_comment].body

    assert_equal(actual_hidden_body, expected_hidden_body)
  end
end
