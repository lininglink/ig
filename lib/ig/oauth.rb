# frozen_string_literal: true

module Ig
  # Unified Login: the client logs in with Instagram or Facebook, picks their
  # business portfolio and the Instagram account(s) to share, and we get a
  # Business Integration System User Access Token for those assets.
  # https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/authentication
  module OAuth
    Token = Struct.new(:access_token, :expires_at, keyword_init: true)

    module_function

    # Where the team member is sent to log in and share an Instagram account.
    # Same parameters as the Login URL the App Dashboard shows for the
    # configuration; prompt=login lets them switch to another account.
    def authorize_url(redirect_uri:, state:)
      query = {
        client_id: config.client_id,
        config_id: config.config_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        override_default_response_type: true,
        state: state,
        prompt: "login"
      }
      "#{AUTHORIZE_URL}?#{URI.encode_www_form(query)}"
    end

    # Exchanges the authorization code for the system-user access token.
    # With the "Never" expiration the response has no expires_in.
    def exchange_code(code, redirect_uri:)
      body = Request.get Ig.graph_url("oauth/access_token"),
        client_id: config.client_id,
        client_secret: config.client_secret,
        redirect_uri: redirect_uri,
        code: code
      expires_in = body["expires_in"].to_i
      Token.new(access_token: body["access_token"], expires_at: (Time.now + expires_in if expires_in.positive?))
    end

    def config
      Ig.configuration
    end
  end
end
