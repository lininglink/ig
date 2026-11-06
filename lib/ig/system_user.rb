# frozen_string_literal: true

module Ig
  # The business integration system user a Unified Login token belongs to.
  # /me is this system user, not the Instagram account.
  class SystemUser
    attr_reader :access_token

    def initialize(access_token:)
      @access_token = access_token
    end

    # The client's business portfolio, needed to manage the token later
    def client_business_id
      get("me", fields: "client_business_id")["client_business_id"]
    end

    # IDs of the Instagram professional accounts the client shared
    def instagram_account_ids
      get("me/assigned_instagram_accounts")["data"].to_a.map { |account| account["id"].to_s }
    end

    private

    def get(path, params = {})
      Request.get(Ig.graph_url(path), params.merge(access_token: access_token))
    end
  end
end
