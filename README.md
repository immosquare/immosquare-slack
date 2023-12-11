# Immosquare Slack

Easily interact with the Slack API from your Ruby applications. This gem allows you to perform actions such as posting messages to channels, fetching user lists, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'immosquare-slack'
```

Then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install immosquare-slack
```

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
ImmosquareSlack::Channel.post_message(channel_name, text, notify: nil, notify_text: nil, bot_name: nil)
```

**Parameters**:

- `channel_name`: String. The name of the Slack channel.

- `text`: String. The primary text of the message to be posted in the channel.

- `notify`: Optional. Specifies the users to be notified. It can be:

  - An array of email addresses: Notifies specific users whose email addresses are provided with @name1, @name2

  - `:channel`: Notifies all users in the channel with @channel

  - `:all`: Notifies all users in the Slack workspace. with @name1, @name2...

- `notify_text`: Optional. Custom text that precedes the notification. If not provided, a default greeting like "Hello" is used.

- `bot_name`: Optional. The name of the bot posting the message. If not provided, the default app name is used.

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

Bug reports and pull requests are welcome on GitHub at [https://github.com/immosquare/immosquare-slack](https://github.com/immosquare/immosquare-slack). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [contributor covenant code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct/).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
