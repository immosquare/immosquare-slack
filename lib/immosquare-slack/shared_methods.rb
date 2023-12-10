module ImmosquareSlack
  module SharedMethods
    private

    ##============================================================##
    ## On récupère tous les résultats avec une loop sur le cursor
    ##============================================================##
    def fetch_paginated_data(url, data_key, extra_query = {})
      items  = []
      cursor = nil

      loop do
        query = cursor ? {:cursor => cursor}.merge(extra_query) : extra_query
        response = make_slack_api_call(url, :query => query)


        items.concat(response[data_key])
        cursor = response.dig("response_metadata", "next_cursor")
        break if cursor.nil? || cursor.empty?
      end
      items
    end

    ##============================================================##
    ## On fait le call à l'API Slack. On raise le message entier
    ## en string si la réponse n'est pas "ok" ou si la réponse
    ## n'est pas un JSON valide.
    ##============================================================##
    def make_slack_api_call(url, method: :get, query: {}, body: nil)
      options = {
        :headers => {
          "Authorization" => "Bearer #{ImmosquareSlack.configuration.slack_api_token_bot}",
          "Content-Type"  => "application/json"
        }
      }

      ##============================================================##
      ## On crée les options en fonction du cas de figure
      ##============================================================##
      options[:query] = query if query.any?
      options[:body]  = body.to_json if body

      ##============================================================##
      ## On send la requête et on parse la réponse
      ##============================================================##
      response        = HTTParty.send(method, url, options)
      parsed_response = JSON.parse(response.body)
      raise(parsed_response.to_json) unless parsed_response["ok"]

      parsed_response
    rescue JSON::ParserError
      raise("Invalid JSON response")
    end
  end
end
