# frozen_string_literal: true

require 'test_helper'

class NewsSummaryTest < MiniTest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_parse_raw_summary
    page_index = '4'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)

    expected_news_summary = page.get_summary(0, false)
    actual_news_summary = ::Wagg::Crawler::NewsSummary.new(page.get_summary(0, true))



    assert_equal(expected_news_summary.id, actual_news_summary.id)
  end
end
