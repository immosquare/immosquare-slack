require "immosquare-slack"

namespace :immosquare_slack do
  desc "Slack tasks"
  namespace :sample do
    ##=============================================================##
    ## Load config keys from config_dev.yml
    ##=============================================================##
    def load_config
      path = "#{File.dirname(__FILE__)}/config_dev.yml"
      abort("Error: config_dev.yml not found") if !File.exist?(path)

      ##=============================================================##
      ## Load config keys from config_dev.yml
      ##=============================================================##
      dev_config = ImmosquareSlack.parse(path)
      abort("Error config_dev.yml is empty") if dev_config.nil?

      ImmosquareSlack.config do |config|
        config.slack_api_token_bot = dev_config["slack_api_token_bot"]
      end
    end



    ##=============================================================##
    ## Send Message to Sack Channel
    ##=============================================================##
    desc "Send Message to Sack Channel"
    task :send_message do
      load_config
      ImmosquareSlack::Channel.send_message("test", "Hello World")
    end
  end
end
