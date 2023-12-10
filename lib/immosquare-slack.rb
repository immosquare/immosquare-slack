require_relative "immosquare-slack/configuration"
require_relative "immosquare-slack/shared_methods"
require_relative "immosquare-slack/channel"
require_relative "immosquare-slack/user"


##===========================================================================##
##
##===========================================================================##
module ImmosquareSlack
  class << self

    ##===========================================================================##
    ## Gem configuration
    ##===========================================================================##
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      yield(configuration)
    end



  end
end
