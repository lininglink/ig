# frozen_string_literal: true

require "test_helper"

class TestIg < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ig::VERSION
  end

  def test_graph_url_uses_the_configured_version
    assert_equal "https://graph.facebook.com/v27.0/me", Ig.graph_url("me")
  end
end
