# frozen_string_literal: true

require "test_helper"

class TestOAuth < Minitest::Test
  def setup
    @config = Ig.configuration.dup
    Ig.configure do |config|
      config.client_id = "meta-app-id"
      config.client_secret = "meta-app-secret"
      config.config_id = "login-config"
    end
  end

  def teardown
    Ig.instance_variable_set(:@configuration, @config)
  end

  def test_authorize_url_uses_the_login_configuration_instead_of_scopes
    url = URI(Ig::OAuth.authorize_url(redirect_uri: "https://example.com/instagram/auth", state: "abc"))
    query = URI.decode_www_form(url.query).to_h

    assert_equal "https://www.facebook.com/dialog/oauth", "#{url.scheme}://#{url.host}#{url.path}"
    assert_equal "meta-app-id", query["client_id"]
    assert_equal "login-config", query["config_id"]
    assert_equal "code", query["response_type"]
    assert_equal "true", query["override_default_response_type"]
    assert_equal "https://example.com/instagram/auth", query["redirect_uri"]
    assert_equal "abc", query["state"]
    assert_nil query["scope"]
  end

  def test_exchange_code_gets_a_token_that_does_not_expire
    Ig::Request.stub(:get, ->(url, params) {
      assert_equal "https://graph.facebook.com/v27.0/oauth/access_token", url
      assert_equal({ client_id: "meta-app-id", client_secret: "meta-app-secret", code: "the-code" },
        params.slice(:client_id, :client_secret, :code))
      { "access_token" => "suat", "token_type" => "bearer" }
    }) do
      token = Ig::OAuth.exchange_code("the-code", redirect_uri: "https://example.com/instagram/auth")
      assert_equal "suat", token.access_token
      assert_nil token.expires_at
    end
  end

  def test_exchange_code_keeps_an_expiry_when_meta_sends_one
    Ig::Request.stub(:get, ->(*) { { "access_token" => "suat", "expires_in" => 3600 } }) do
      assert_in_delta Time.now + 3600, Ig::OAuth.exchange_code("c", redirect_uri: "r").expires_at, 5
    end
  end
end
