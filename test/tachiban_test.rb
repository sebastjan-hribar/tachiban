require 'test_helper'

class TachibanTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tachiban::VERSION
  end
end
