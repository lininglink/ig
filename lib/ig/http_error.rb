# frozen_string_literal: true

module Ig
  # The API answered with an error object, e.g.
  #   {"error": {"message": "...", "type": "OAuthException", "code": 190}}
  class HTTPError < Error
    attr_reader :status, :code, :type

    def initialize(message, status: nil, code: nil, type: nil)
      super(message)
      @status = status
      @code = code
      @type = type
    end

    # Code 190 means the access token is expired or was revoked
    def invalid_token?
      code == 190
    end
  end
end
