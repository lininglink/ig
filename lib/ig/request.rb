# frozen_string_literal: true

require "net/http"
require "json"

module Ig
  # Sends one HTTP request and returns the parsed JSON body, or raises
  # Ig::HTTPError with the message the API gave.
  module Request
    module_function

    def get(url, params = {})
      uri = URI(url)
      uri.query = URI.encode_www_form(params.compact) if params.any?
      perform uri, Net::HTTP::Get.new(uri)
    end

    def post_form(url, params = {})
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params.compact)
      perform uri, request
    end

    def perform(uri, request)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
        http.request(request)
      end
      body = parse(response.body)
      raise error_for(response, body) unless response.is_a?(Net::HTTPSuccess)

      body
    end

    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      { "error" => { "message" => body.to_s[0, 200] } }
    end

    # Graph errors come as {"error": {...}}; OAuth errors on api.instagram.com
    # sometimes come flat, as {"error_type": ..., "code": ..., "error_message": ...}
    def error_for(response, body)
      error = body["error"].is_a?(Hash) ? body["error"] : body
      message = error["message"] || error["error_message"] || "HTTP #{response.code}"
      HTTPError.new(message, status: response.code.to_i, code: error["code"], type: error["type"] || error["error_type"])
    end
  end
end
