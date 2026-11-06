# frozen_string_literal: true

module Ig
  # An Instagram professional account (business or creator) reached with a
  # Unified Login access token.
  # https://developers.facebook.com/documentation/instagram-platform/reference/instagram-user
  class User
    PROFILE_FIELDS = %w[
      id username name profile_picture_url
      followers_count follows_count media_count
    ].freeze

    # Account insights take at most 30 days between since and until
    MAX_INSIGHTS_DAYS = 30

    attr_reader :id, :access_token

    # @param id [String] the Instagram professional account ID
    def initialize(id:, access_token:)
      @access_token = access_token
      @id = id
    end

    # GET /<IG_ID>?fields=id,username,...
    def profile(fields: PROFILE_FIELDS)
      get(id, fields: Array(fields).join(","))
    end

    # Media on the account, newest first, following pagination up to limit.
    # GET /<IG_ID>/media
    def media(limit: 25, fields: Media::FIELDS)
      items = []
      body = get("#{id}/media", fields: fields.join(","), limit: [limit, 100].min)
      loop do
        items.concat body["data"].map { |hash| Media.new(hash, access_token: access_token) }
        next_url = body.dig("paging", "next")
        break if items.size >= limit || next_url.to_s.empty?

        body = Request.get(next_url)
      end
      items.first(limit)
    end

    # GET /<IG_ID>/insights
    # https://developers.facebook.com/documentation/instagram-platform/reference/instagram-user/insights
    def insights(params)
      get("#{id}/insights", params)
    end

    # The total of an interaction metric (views, reach, accounts_engaged, ...)
    # for the days from..to, inclusive. Ranges longer than 30 days are asked
    # for in pieces and added up, so unique-account metrics such as reach can
    # count an account once per piece.
    #
    # @return [Integer, nil] nil when the API has no data for the metric
    def insights_total(metric, from:, to:)
      values = date_chunks(from, to).map do |chunk_from, chunk_to|
        body = insights(
          metric: metric,
          period: "day",
          metric_type: "total_value",
          since: day_start(chunk_from),
          until: day_start(chunk_to + 1)
        )
        body["data"].find { |h| h["name"] == metric.to_s }&.dig("total_value", "value")
      end
      values.compact.sum if values.any?
    end

    private

    # Unix time of midnight at the start of date: in Time.zone when
    # ActiveSupport has one (as in Rails), otherwise in the local time zone
    def day_start(date)
      return date.in_time_zone.to_i if date.respond_to?(:in_time_zone)

      Time.local(date.year, date.month, date.day).to_i
    end

    def date_chunks(from, to)
      chunks = []
      start = from
      while start <= to
        finish = [start + (MAX_INSIGHTS_DAYS - 1), to].min
        chunks << [start, finish]
        start = finish + 1
      end
      chunks
    end

    def get(path, params = {})
      Request.get(Ig.graph_url(path), params.merge(access_token: access_token))
    end
  end
end
