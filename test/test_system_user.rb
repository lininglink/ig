# frozen_string_literal: true

require "test_helper"

class TestSystemUser < Minitest::Test
  def setup
    @system_user = Ig::SystemUser.new(access_token: "suat")
  end

  def test_instagram_account_ids_reads_the_assigned_accounts
    Ig::Request.stub(:get, ->(url, params) {
      assert_equal "https://graph.facebook.com/v27.0/me/assigned_instagram_accounts", url
      assert_equal "suat", params[:access_token]
      { "data" => [{ "id" => 17841400000000001 }, { "id" => "17841400000000002" }] }
    }) do
      assert_equal %w[17841400000000001 17841400000000002], @system_user.instagram_account_ids
    end
  end

  def test_instagram_account_ids_is_empty_when_nothing_was_shared
    Ig::Request.stub(:get, ->(*) { { "data" => [] } }) do
      assert_empty @system_user.instagram_account_ids
    end
  end

  def test_client_business_id_comes_from_me
    Ig::Request.stub(:get, ->(url, params) {
      assert_equal "https://graph.facebook.com/v27.0/me", url
      assert_equal "client_business_id", params[:fields]
      { "id" => "122", "client_business_id" => "9001" }
    }) do
      assert_equal "9001", @system_user.client_business_id
    end
  end
end
