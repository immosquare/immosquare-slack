module ImmosquareSlack
  class Configuration

    attr_accessor :slack_api_token_bot, :default_channel, :default_bot_name

    def initialize
      @slack_api_token_bot = nil
      @default_channel     = nil
      @default_bot_name    = nil
    end

  end
end
