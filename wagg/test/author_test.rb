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
    assert_equal(@author.id, 1)
  end
end