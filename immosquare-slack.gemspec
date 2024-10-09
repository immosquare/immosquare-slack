require_relative "lib/immosquare-slack/version"


Gem::Specification.new do |spec|
  spec.license       = "MIT"
  spec.name          = "immosquare-slack"
  spec.version       = ImmosquareSlack::VERSION.dup
  spec.authors       = ["immosquare"]
  spec.email         = ["jules@immosquare.com"]

  spec.summary       = "A Ruby gem for integrating with Slack API to perform various actions like posting messages."
  spec.description   = "ImmosquareSlack is a Ruby gem that provides an easy and efficient way to integrate Ruby applications with Slack. It leverages the Slack API to enable functionalities such as posting messages, managing channels, and other Slack-related operations. Designed for simplicity and ease of use, this gem is ideal for developers looking to enhance their Ruby applications with Slack's communication capabilities."

  spec.homepage      = "https://github.com/IMMOSQUARE/immosquare-slack"

  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")

  spec.add_dependency("httparty", "~> 0")
end
