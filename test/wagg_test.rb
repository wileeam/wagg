# encoding: utf-8

require "test_helper"

class WaggTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Wagg::VERSION
  end
end