# frozen_string_literal: true

require 'test_helper'

class AuthorTest < MiniTest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_that_admin_profile_is_static
    author = 'admin'
    signup = DateTime.strptime('17-11-2016 14:18 UTC', '%d-%m-%Y %H:%M %Z')
    @author = ::Wagg.author(author)

    # admin has a fixed name... admin
    assert_equal(@author.name, 'admin')
    # admin was 'born' not so long ago...
    assert_equal(@author.signup, signup)
    # admin karma is static and 6
    assert_equal(@author.karma, 6)
    # admin does not have friends
    assert_equal(@author.friends.length, 0)
    # admin is liked by some people though
    assert_operator(@author.friends_of.length, :>=, 0)
    # admin does not have any sub community of its own
    assert_equal(@author.subs_own.length, 0)
    # admin does not follow any sub community
    assert_equal(@author.subs_follow.length, 0)
  end

  def test_that_disabled_user_is_disabled
    disabled_author = '--637844--'
    @author = ::Wagg.author(disabled_author)

    assert(@author.disabled?)
  end

  def test_get_id_author
    id_author = 'neotobarra2'
    author = ::Wagg.author(id_author)

    expected_id = 292_897
    actual_id = author.id

    assert_equal(expected_id, actual_id)
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
    assert_operator(author.subs_follow.length, '>=', 10)
  end

  def test_get_enabled_author_page
    enabled_author = 'nereira'
    author = ::Wagg.author(enabled_author)

    assert_equal(author.name, enabled_author)
    assert(!author.disabled?)
  end

  def test_get_disabled_author_page
    disabled_author = '--334312--'
    author = ::Wagg.author(disabled_author)

    assert_equal(author.name, disabled_author)
    assert(author.disabled?)
  end

  def test_to_json_from_json
    random_author = 'Gaveta'
    author = ::Wagg.author(random_author)

    expected_author_json = author.to_json

    actual_author = ::Wagg::Crawler::Author.from_json(expected_author_json)
    actual_author_json = actual_author.to_json

    assert_equal(expected_author_json, actual_author_json)
  end
end
