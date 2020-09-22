# encoding: utf-8

require "test_helper"

class AuthorTest < MiniTest::Test
  def setup
    author = 'admin'
    @author = ::Wagg.author(author)
  end

  def teardown
    # Do nothing
  end

  def test
    skip 'Not implemented'
  end

  def test_that_name_of_admin_is_admin
    assert_equal(@author.name, "admin")
    # assert_equal(@author.id, 1)
  end

  def test_pattern_of_disabled_users
    disabled_author = ::Wagg.author('--12345--')
    assert(disabled_author.disabled)
  end

  def test_pattern_of_non_disabled_users
    non_disabled_author = ::Wagg.author('--Gepeto--')
    assert(!non_disabled_author.disabled)

    non_disabled_author = ::Wagg.author('Gepeto')
    assert(!non_disabled_author.disabled)

    non_disabled_author = ::Wagg.author('Gepeto--')
    assert(!non_disabled_author.disabled)

    non_disabled_author = ::Wagg.author('--Gepeto')
    assert(!non_disabled_author.disabled)

    non_disabled_author = ::Wagg.author('--12Gepeto34--')
    assert(!non_disabled_author.disabled)
  end

  def test_retrieve_author

  end
end