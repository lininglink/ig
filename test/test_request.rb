# frozen_string_literal: true

require "test_helper"

class TestRequest < Minitest::Test
  Response = Struct.new(:code)

  def test_error_for_reads_graph_errors
    body = { "error" => { "message" => "Invalid OAuth access token", "type" => "OAuthException", "code" => 190 } }
    error = Ig::Request.error_for(Response.new("400"), body)

    assert_equal "Invalid OAuth access token", error.message
    assert error.invalid_token?
    assert_equal 400, error.status
  end

  def test_error_for_reads_flat_oauth_errors
    body = { "error_type" => "OAuthException", "code" => 400, "error_message" => "Invalid authorization code" }
    error = Ig::Request.error_for(Response.new("400"), body)

    assert_equal "Invalid authorization code", error.message
    assert_equal "OAuthException", error.type
  end

  def test_parse_keeps_the_start_of_a_non_json_body
    assert_equal "x" * 200, Ig::Request.parse("x" * 300).dig("error", "message")
  end
end
