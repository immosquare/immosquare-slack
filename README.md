# Immosquare Slack

Easily interact with the Slack API from your Ruby applications. This gem allows you to perform actions such as posting messages to channels, fetching user lists, and more.

## Installation

Add this line to your Gemfile:

```ruby
gem "immosquare-slack"
```

Then execute:

```bash
bundle install
```

## Configuration

Before using `immosquare-slack`, you need to configure it with your Slack API token. Create an initializer file in your Ruby application (e.g., `config/initializers/immosquare_slack.rb`) with the following content:

```ruby
ImmosquareSlack.config do |config|
  config.slack_api_token_bot = ENV.fetch("slack_api_token_bot", nil)

  # Optional — used as fallback when `channel_name` / `bot_name`
  # are not passed to `Channel.post_message`. Lets apps that
  # always notify the same channel avoid repeating the value
  # at every call site.
  config.default_channel  = "dev-team-monitoring"
  config.default_bot_name = "immosquare bot"
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
ImmosquareSlack::Channel.post_message(text, channel_name: nil, notify: nil, notify_text: nil, bot_name: nil, notify_general_if_invalid_channel: true)
```

**Parameters**:

| Parameter                           | Required | Default                                          | Description                                                                                         |
| ----------------------------------- | -------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `text`                              | Yes      | —                                                | The main content of the message.                                                                    |
| `channel_name`                      | No       | `ImmosquareSlack.configuration.default_channel`  | The name of the Slack channel. Raises `ArgumentError` if no channel can be resolved after fallback. |
| `notify`                            | No       | `nil`                                            | Who to notify (see accepted values below).                                                          |
| `notify_text`                       | No       | `"Hello"`                                        | Custom text that precedes the notification.                                                         |
| `bot_name`                          | No       | `ImmosquareSlack.configuration.default_bot_name` | Name of the bot posting the message.                                                                |
| `notify_general_if_invalid_channel` | No       | `true`                                           | If the channel is invalid, notify the general channel.                                              |

**Accepted values for `notify`**:

| Value           | Behavior                                                                 |
| --------------- | ------------------------------------------------------------------------ |
| Array of emails | Notifies specific users if their email is linked to their Slack user ID. |
| `:channel`      | Notifies all members of the channel.                                     |
| `:here`         | Notifies members currently active in the channel.                        |
| `:everyone`     | Notifies every member of the workspace (use with caution).               |
| `:all`          | Notifies all members of the channel individually (mentions each user).   |

**Example**:

Using the `post_message` method, you can post a message in a Slack channel and customize notifications. Here's how you can use the method with all parameters:

```ruby
ImmosquareSlack::Channel.post_message(
  "This is a test message",
  channel_name: "test",
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

**Shorthand with defaults**:

If `default_channel` and `default_bot_name` are set in the configuration, you can omit them:

```ruby
ImmosquareSlack::Channel.post_message("This is a test message", notify: :channel)
```

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
