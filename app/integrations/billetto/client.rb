require "json"
require "rest-client"

module Billetto
  class Client
    BASE_URL = "https://billetto.dk"
    DEFAULT_LIMIT = 10

    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ApiError < Error; end
    class RequestError < Error; end
    class InvalidResponseError < Error; end

    def initialize(api_keypair: Rails.application.credentials.dig(:billetto, :api_keypair))
      raise AuthenticationError, "Billetto API key pair is missing" if api_keypair.blank?

      @api_keypair = api_keypair
    end

    def fetch_events(limit: DEFAULT_LIMIT, after: nil)
      params = { limit: limit }
      params[:after] = after if after.present?

      response = RestClient.get(
        "#{BASE_URL}/api/v3/public/events",
        {
          accept: :json,
          "Api-Keypair" => @api_keypair,
          params: params
        }
      )

      parse_response(response.body)
    rescue RestClient::Unauthorized, RestClient::Forbidden => e
      raise AuthenticationError, "Billetto authentication failed: #{e.http_code}"
    rescue RestClient::ExceptionWithResponse => e
      raise ApiError, "Billetto API returned HTTP #{e.http_code}"
    rescue RestClient::Exception, SocketError, Timeout::Error => e
      raise RequestError, "Billetto request failed: #{e.message}"
    end

    private

    def parse_response(body)
      result = JSON.parse(body)

      unless result.is_a?(Hash) && result["data"].is_a?(Array)
        raise InvalidResponseError, "Unexpected Billetto API response format"
      end

      result
    rescue JSON::ParserError
      raise InvalidResponseError, "Billetto returned invalid JSON"
    end
  end
end
