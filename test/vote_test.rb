# encoding: utf-8

require "test_helper"

class VoteTest < MiniTest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  # It can fail (rarely) due to race conditions of news vs votes retrievals
  # Actual number of votes can be higher than statistics' votes counter (unknown reason, possibly bug on site)
  def test_get_news_votes
    page_index = '3'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)
    first_news = page.news_list.first

    assert_equal(first_news.statistics.num_votes, first_news.statistics.positive_votes + first_news.statistics.negative_votes)
    assert_equal(first_news.votes.num_votes, first_news.votes.positive_votes + first_news.votes.negative_votes)

    assert_operator(first_news.votes.positive_votes, :>=, first_news.statistics.positive_votes)
    assert_operator(first_news.votes.negative_votes, :>=, first_news.statistics.negative_votes)
    assert_operator(first_news.votes.num_votes, :>=, first_news.statistics.num_votes)
  end

  # It can fail (rarely) due to race conditions of news vs votes retrievals
  def test_get_comment_votes
    page_index = '1'
    page_type = 'published'
    page = ::Wagg.page(page_index, page_type)
    last_news_full = ::Wagg::Crawler::News.new(page.news_list.last.id_extended, 'html')
    first_comment_last_news = last_news_full.comments.first

    expected_num_votes = first_comment_last_news.statistics.num_votes
    actual_votes_num_votes = first_comment_last_news.votes.num_votes
    assert_equal(expected_num_votes, actual_votes_num_votes)
  end

end