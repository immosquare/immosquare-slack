require "json"
require "httparty"

module ImmosquareSlack
  module SharedMethods
    private

    ##============================================================##
    ## Fetches all results by looping on the Slack API cursor.
    ##============================================================##
    def fetch_paginated_data(url, data_key, extra_query = {})
      items  = []
      cursor = nil

      loop do
        query    = cursor ? {:cursor => cursor}.merge(extra_query) : extra_query
        response = make_slack_api_call(url, :query => query)
        cursor   = response.dig("response_metadata", "next_cursor")

        items.concat(response[data_key])
        break if cursor.nil? || cursor.empty?
      end
      items
    end

    ##============================================================##
    ## Calls the Slack API. Raises the full response body as a
    ## string if the response is not "ok" or if the body is not
    ## valid JSON.
    ##============================================================##
    def make_slack_api_call(url, method: :get, query: {}, body: nil)
      options = {
        :headers => {
          "Authorization" => "Bearer #{ImmosquareSlack.configuration.slack_api_token_bot}",
          "Content-Type"  => "application/json"
        }
      }

      ##============================================================##
      ## Builds the request options based on the call type.
      ##============================================================##
      options[:query] = query        if query.any?
      options[:body]  = body.to_json if body

      ##============================================================##
      ## Sends the request and parses the response.
      ##============================================================##
      response        = HTTParty.public_send(method, url, options)
      parsed_response = JSON.parse(response.body)
      raise(parsed_response.to_json) if !parsed_response["ok"]

      parsed_response
    rescue JSON::ParserError
      raise("Invalid JSON response")
    end
  end
end
