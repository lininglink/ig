# frozen_string_literal: true

require "test_helper"

class TestUser < Minitest::Test
  def setup
    @user = Ig::User.new(id: "1784", access_token: "token")
  end

  def test_profile_reads_the_account_by_its_id
    Ig::Request.stub(:get, ->(url, params) {
      assert_equal "https://graph.facebook.com/v27.0/1784", url
      assert_equal "token", params[:access_token]
      assert_includes params[:fields], "followers_count"
      { "id" => "1784", "username" => "brand" }
    }) do
      assert_equal "brand", @user.profile["username"]
    end
  end

  def test_insights_total_asks_with_total_value_and_day_aligned_unix_timestamps
    calls = []
    Ig::Request.stub(:get, ->(url, params) {
      calls << [url, params]
      { "data" => [{ "name" => "views", "total_value" => { "value" => 120 } }] }
    }) do
      assert_equal 120, @user.insights_total(:views, from: Date.new(2026, 9, 1), to: Date.new(2026, 9, 30))
    end

    assert_equal 1, calls.size
    url, params = calls.first
    assert_equal "https://graph.facebook.com/v27.0/1784/insights", url
    assert_equal({ metric: :views, period: "day", metric_type: "total_value" }, params.slice(:metric, :period, :metric_type))
    assert_equal Time.local(2026, 9, 1).to_i, params[:since]
    assert_equal Time.local(2026, 10, 1).to_i, params[:until]
  end

  def test_insights_total_splits_ranges_over_30_days_and_adds_the_pieces
    calls = []
    Ig::Request.stub(:get, ->(_, params) {
      calls << params
      { "data" => [{ "name" => "reach", "total_value" => { "value" => 10 } }] }
    }) do
      assert_equal 20, @user.insights_total(:reach, from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31))
    end

    assert_equal [Time.local(2026, 10, 1), Time.local(2026, 10, 31)].map(&:to_i), calls.map { |c| c[:since] }
    assert_equal [Time.local(2026, 10, 31), Time.local(2026, 11, 1)].map(&:to_i), calls.map { |c| c[:until] }
  end

  def test_insights_total_is_nil_when_the_api_returns_an_empty_data_set
    Ig::Request.stub(:get, ->(*) { { "data" => [] } }) do
      assert_nil @user.insights_total(:views, from: Date.new(2026, 9, 1), to: Date.new(2026, 9, 7))
    end
  end

  def test_media_follows_paging_until_the_limit
    page1 = { "data" => [{ "id" => "1" }, { "id" => "2" }], "paging" => { "next" => "https://graph.facebook.com/next" } }
    page2 = { "data" => [{ "id" => "3" }, { "id" => "4" }], "paging" => { "next" => "https://graph.facebook.com/next2" } }
    urls = []
    Ig::Request.stub(:get, ->(url, _ = {}) {
      urls << url
      url.end_with?("/next") ? page2 : page1
    }) do
      assert_equal %w[1 2 3], @user.media(limit: 3).map(&:id)
    end
    assert_equal ["https://graph.facebook.com/v27.0/1784/media", "https://graph.facebook.com/next"], urls
  end

  def test_media_published_at_is_parsed_from_the_timestamp
    media = Ig::Media.new({ "timestamp" => "2026-09-01T16:30:00+0000" }, access_token: "token")
    assert_equal Time.utc(2026, 9, 1, 16, 30), media.published_at
  end
end
