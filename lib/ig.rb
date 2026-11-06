# frozen_string_literal: true

require_relative "ig/version"
require_relative "ig/error"
require_relative "ig/http_error"
require_relative "ig/request"
require_relative "ig/oauth"
require_relative "ig/system_user"
require_relative "ig/media"
require_relative "ig/user"

# A small client for the Instagram API with Unified Login.
# https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login
module Ig
  GRAPH_HOST = "https://graph.facebook.com"
  AUTHORIZE_URL = "https://www.facebook.com/dialog/oauth"

  # client_id and client_secret are the Meta app ID and secret. config_id is
  # the Unified login configuration from the App Dashboard: it sets the
  # permissions (instagram_basic, instagram_manage_insights), the assets and
  # the token type, so the login URL carries no scope.
  Configuration = Struct.new(:client_id, :client_secret, :config_id, :api_version)

  class << self
    def configuration
      @configuration ||= Configuration.new(nil, nil, nil, "v27.0")
    end

    def configure
      yield configuration
    end

    def graph_url(path)
      "#{GRAPH_HOST}/#{configuration.api_version}/#{path}"
    end
  end
end
