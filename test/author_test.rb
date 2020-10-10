# encoding: utf-8

require "test_helper"

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

  def test_that_disabled_users_are_disabled
    disabled_author = '--637844--'
    @author = ::Wagg.author(disabled_author)

    assert(@author.disabled)
  end

end