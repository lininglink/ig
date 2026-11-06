# frozen_string_literal: true

require "time"

module Ig
  # An IG Media object: a post, reel, story or carousel album
  # https://developers.facebook.com/documentation/instagram-platform/reference/instagram-media
  class Media
    FIELDS = %w[
      id caption media_type media_product_type media_url thumbnail_url
      permalink timestamp like_count comments_count
    ].freeze

    attr_reader :attributes, :access_token

    def initialize(attributes, access_token:)
      @attributes = attributes
      @access_token = access_token
    end

    FIELDS.each do |field|
      define_method(field) { attributes[field] }
    end

    # UTC; call in_time_zone (Rails) or localtime to show it elsewhere
    def published_at
      Time.iso8601(timestamp) if timestamp
    end

    def video?
      media_type == "VIDEO"
    end

    # An image Google Slides can place: videos have a thumbnail_url, images
    # and albums a media_url
    def picture
      video? ? thumbnail_url : media_url
    end

    # GET /<IG_MEDIA_ID>/insights?metric=views,reach,...
    def insights(metric:)
      Request.get(Ig.graph_url("#{id}/insights"),
        metric: Array(metric).join(","), access_token: access_token)
    end
  end
end
