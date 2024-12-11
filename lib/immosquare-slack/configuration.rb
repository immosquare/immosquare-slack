module ImmosquareSlack
  class Configuration

    attr_accessor :slack_api_token_bot

    def initialize
      @slack_api_token_bot = nil
    end

  end
end
