---
created_at: "2023-12-10"
updated_at: "2026-10-21"
locale: en
tags:
  - app:immosquare-slack
  - audience:technique
---

# immosquare-slack

`immosquare-slack` lets a Ruby application interact with the Slack API: posting messages to channels, fetching user lists, and more. This page covers installing the gem, configuring the Slack bot token it authenticates with, the `ImmosquareSlack::Channel` and `ImmosquareSlack::User` methods it exposes, and the errors those methods raise. It requires Ruby >= 3.2.6 and a Slack app whose bot token carries the `channels:read`, `groups:read`, `chat:write`, `chat:write.customize`, `users:read` and `users:read.email` scopes.

## Installing immosquare-slack and configuring the Slack API token

Requires Ruby >= 3.2.6.

Add this line to your Gemfile:

```ruby
gem "immosquare-slack"
```

Then execute:

```bash
bundle install
```

Before using `immosquare-slack`, you need to configure it with your Slack API token. Create an initializer file in your Ruby application (e.g., `config/initializers/immosquare_slack.rb`) with the following content:

```ruby
ImmosquareSlack.config do |config|
  config.slack_api_token_bot = ENV.fetch("slack_api_token_bot", nil)
  config.default_channel     = "dev-team-monitoring"
  config.default_bot_name    = "immosquare bot"
end
```

`ImmosquareSlack.config` accepts four options — the token used to authenticate, two values that act as fallbacks when a call omits them, and a switch for the direct messages sent to mentioned users outside the channel:

| Option                                | Type    | Default | Description                                                                                                                  |
| ------------------------------------- | ------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `slack_api_token_bot`                 | String  | `nil`   | Bot token sent as `Authorization: Bearer` on every API call.                                                                 |
| `default_channel`                     | String  | `nil`   | Channel used when `channel_name` is not passed to `Channel.post_message`.                                                    |
| `default_bot_name`                    | String  | `nil`   | Bot display name used when `bot_name` is not passed to `Channel.post_message`.                                               |
| `direct_message_unreachable_mentions` | Boolean | `true`  | Also send the message as a direct message to users mentioned by email who are not in the channel the message lands in.       |

The two defaults let an application that always notifies the same channel avoid repeating the value at every call site.

To get your Slack API token, follow these steps:

* Go to the [Slack API website](https://api.slack.com/).

* Click on "Create New App".

* Fill in the required information and click on "Create App".

* In the "OAuth & Permissions" section, you will find your API token.

* Be sure to add the following scopes to your app: `channels:read`, `groups:read`, `chat:write`, `chat:write.customize`, `users:read`, `users:read.email` in the Bot Token Scopes section. `chat:write.customize` is required for `bot_name` to be sent as the message username, and `users:read.email` is required for a list of email addresses passed to `notify` to be resolved to member ids.

## Listing the channels and the users of the workspace

`ImmosquareSlack::Channel.list_channels` retrieves every channel of the workspace — public and private, archived included.

```ruby
ImmosquareSlack::Channel.list_channels
```

The result is memoized for the lifetime of the process, so a long-running Puma worker or Sidekiq process keeps serving the list it fetched on its first call. A channel created or renamed afterwards is absent from it. Pass `force: true` to drop the cache and refetch:

```ruby
ImmosquareSlack::Channel.list_channels(force: true)
```

`ImmosquareSlack::User.list_users` gets a list of all users.

```ruby
ImmosquareSlack::User.list_users
```

## Posting a message with ImmosquareSlack::Channel.post_message

`ImmosquareSlack::Channel.post_message` posts a message to a specific channel. You can customize the message by using the following parameters:

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
| `bot_name`                          | No       | `ImmosquareSlack.configuration.default_bot_name` | Display name sent as `username`. Requires the `chat:write.customize` scope.                         |
| `notify_general_if_invalid_channel` | No       | `true`                                           | If the channel cannot be resolved, post to the general channel instead of raising (see below).      |

**Accepted values for `notify`**:

| Value           | Behavior                                                                                                                                            |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Array of emails | Mentions active members whose `profile.email` is in the list, and sends a direct message to those outside the channel. Requires `users:read.email`. |
| `:channel`      | Notifies all members of the channel.                                                                                                                |
| `:here`         | Notifies members currently active in the channel.                                                                                                   |
| `:everyone`     | Notifies every member of the workspace (use with caution).                                                                                          |
| `:all`          | Notifies all members of the channel individually (mentions each user).                                                                              |

**Example**:

Using the `post_message` method, you can post a message in a Slack channel and customize notifications. Here's how you can use the method with all parameters:

```ruby
ImmosquareSlack::Channel.post_message(
  "This is a test message",
  channel_name: "test",
  notify: ["johnDoe@mail.com"],
  notify_text: "Attention please",
  bot_name: "My Bot"
)
```

`post_message` resolves each address against the workspace member list and writes the member id Slack returned. Slack does not turn a mailbox name written into the text into a mention. The channel receives:

```
Attention please <@U012AB3CD>
This is a test message
```

`<@U012AB3CD>` stands in for the id of the member whose `profile.email` is `johnDoe@mail.com`. An address that matches no active member — unknown, or belonging to a deactivated account — is left out, and so is the whole mention when the token cannot read emails. The message is posted under the name "My Bot". If that member has not joined `#test`, they also receive the message as a direct message from the bot.

**Shorthand with defaults**:

If `default_channel` and `default_bot_name` are set in the configuration, you can omit them:

```ruby
ImmosquareSlack::Channel.post_message("This is a test message", notify: :channel)
```

**When the channel cannot be resolved**:

A lookup miss can mean the channel does not exist, or that the memoized channel list predates its creation. `post_message` refetches the list once before concluding. If the channel is still not found:

- with `notify_general_if_invalid_channel: true` (the default), the message is posted on the general channel. Its text is `<!channel>`, then `immosquare-slack missing channel *<channel_name>*`, then `message:`, then the original text. That second post sets the flag to `false`, so a workspace whose general channel cannot be resolved raises instead of looping. Every member mentioned through an array of emails first receives the original text as a direct message (see "Direct messages to mentioned users outside the channel");
- with `notify_general_if_invalid_channel: false`, a `RuntimeError` is raised.

The general channel is matched on Slack's `is_general` flag rather than on its name, so a workspace that renamed it is still handled.

## Direct messages to mentioned users outside the channel

Slack only notifies a mention to members of the channel the message lands in: a user mentioned in a channel they have not joined gets no notification at all. When `notify` is an array of emails, `ImmosquareSlack::Channel.post_message` therefore also sends the message as a direct message from the bot to each mentioned member who is not in the target channel. Members already in the channel get no direct message, and the `:channel`, `:here`, `:everyone` and `:all` values of `notify` never send one.

The direct message reads `Mentioned in <#channel_id>:` (rendered by Slack as a link to the channel), followed by the original text without the notification prefix. Channel membership is read with `conversations.members` after the channel post, which adds one API call per message whenever at least one email matched and the option is on. When the channel cannot be resolved and the message falls back to the general channel, every mentioned member gets a direct message prefixed with `Mentioned in *#<channel_name>* (channel not found):`, since the general post does not carry their mention.

Direct messages are best effort: a direct message that Slack refuses is skipped, the next one is still sent, and `post_message` returns the response of the channel post. A refused direct message therefore never fails the call, never causes a duplicate channel post when the caller retries, and never prevents the fallback to the general channel.

To keep mentions only, without any direct message, turn the option off:

```ruby
ImmosquareSlack.config do |config|
  config.direct_message_unreachable_mentions = false
end
```

## Errors raised by immosquare-slack

Four situations make an `immosquare-slack` call raise — two when `Channel.post_message` cannot resolve a channel, two when Slack answers something the gem cannot use:

| Situation                                                                   | Raised                                                       |
| --------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `channel_name` omitted and `default_channel` unset                          | `ArgumentError`                                              |
| Channel not found and `notify_general_if_invalid_channel: false`            | `RuntimeError`, `channel '<name>' not found on slack`        |
| Slack answers with `"ok": false`                                            | `RuntimeError` carrying the full response body as JSON       |
| Slack answers with a body that is not valid JSON                            | `RuntimeError`, `Invalid JSON response`                      |

Two exceptions aside — the single channel-list refetch that `post_message` performs before declaring a channel missing, and the direct messages to mentioned users outside the channel, whose refusals are skipped — nothing is retried and no error is swallowed. Wrap the call when a failed notification must not break the caller:

```ruby
begin
  ImmosquareSlack::Channel.post_message("Nightly import finished", channel_name: "monitoring")
rescue StandardError => e
  Rails.logger.error("slack notification failed: #{e.message}")
end
```

## Contributing to immosquare-slack and license

Bug reports and pull requests are welcome on GitHub at [https://github.com/immosquare/immosquare-slack](https://github.com/immosquare/immosquare-slack). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [contributor covenant code of conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

Run the test suite before opening a pull request:

```bash
bundle install
bundle exec rspec
```

The specs stub the Slack API with WebMock, which also blocks any real network call, so they run without a Slack token.

`bin/ci` with no argument installs the dependencies and runs that suite. `bin/ci init` only installs, and `bin/ci test` only runs the suite, which is how a CI job splits the two steps. Coverage is on unless `COVERAGE` is set to a value other than `true`, and the LCOV report is written to `coverage/lcov.info`.

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
