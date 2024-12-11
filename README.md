# Immosquare Slack

Easily interact with the Slack API from your Ruby applications. This gem allows you to perform actions such as posting messages to channels, fetching user lists, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'immosquare-slack'
```

## Configuration

Before using `immosquare-slack`, you need to configure it with your Slack API token. Create an initializer file in your Ruby application (e.g., `config/initializers/immosquare_slack.rb`) with the following content:

```ruby
ImmosquareSlack.config do |config|
  config.slack_api_token_bot = ENV.fetch("slack_api_token_bot", nil)
end
```
To get your Slack API token, follow these steps:

* Go to the [Slack API website](https://api.slack.com/).

* Click on "Create New App".

* Fill in the required information and click on "Create App".

* In the "OAuth & Permissions" section, you will find your API token.

* Be sure to add the following scopes to your app: `channels:read`, `chat:write`, `users:read`, `groups:read` in the Bot Token Scopes section.


## Usage

### Channel Operations

#### List Channels

Retrieve a list of all channels.

```ruby
ImmosquareSlack::Channel.list_channels
```

#### Post a Message

Post a message to a specific channel. You can customize the message by using the following parameters:

```ruby
ImmosquareSlack::Channel.post_message(channel_name, text, notify: nil, notify_text: nil, bot_name: nil, notify_general_if_invalid_channel: true)
```

**Parameters**:

- `channel_name`: String. The name of the Slack channel.

- `text`: String. The main content of the message.

- `notify`: Optional. A specifier for whom to notify. Accepts:

  - An array of email addresses: Notifies specific users if their email is linked to their Slack user ID.

  - `:channel`: Notifies all members of the channel.

  - `:here`: Notifies members currently active in the channel.

  - `:everyone`: Notifies every member of the workspace (use with caution).

- `notify_text`: Optional. Custom text that precedes the notification. (default : "Hello")

- `bot_name`: Optional. Specifies the name of the bot posting the message.

- `notify_general_if_invalid_channel`: Optional. If the channel is invalid, notify the general channel. (default : true)

**Example**:

Using the `post_message` method, you can post a message in a Slack channel and customize notifications. Here's how you can use the method with all parameters:

```ruby
ImmosquareSlack::Channel.post_message(
  "test",
  "This is a test message",
  notify: ["jonhDoe@mail.com"],
  notify_text: "Attention please",
  bot_name: "My Bot"
)
```

This will send a message to the "test" channel that looks like this:

```
Attention please <@johnDoe>
This is a test message
```

In the above message:
- `<@johnDoe>` is a placeholder that Slack will automatically convert to a mention of the user associated with the email "jonhDoe@mail.com".

- "Attention please" is the custom notification text provided in `notify_text`.

- "This is a test message" is the main text of the message.

- The message will appear to be posted by the bot named "My Bot".




### User Operations

#### List Users

Get a list of all users.

```ruby
ImmosquareSlack::User.list_users
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/immosquare/immosquare-slack](https://github.com/immosquare/immosquare-slack). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [contributor covenant code of conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
