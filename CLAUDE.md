# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`immosquare-slack` is a Ruby gem for interacting with the Slack API. It provides functionality for posting messages to channels, listing channels, and fetching users.

## Development Commands

```bash
# Install dependencies
bundle install

# Run sample task (requires config_dev.yml with slack_api_token_bot)
bundle exec rake immosquare_slack:sample:post_message
```

## Architecture

The gem follows a modular structure under the `ImmosquareSlack` namespace:

- **Configuration** (`lib/immosquare-slack/configuration.rb`): Stores `slack_api_token_bot` credential
- **SharedMethods** (`lib/immosquare-slack/shared_methods.rb`): HTTP utilities using HTTParty, handles pagination and API calls
- **Channel** (`lib/immosquare-slack/channel.rb`): Channel operations - `list_channels`, `post_message`
- **User** (`lib/immosquare-slack/user.rb`): User operations - `list_users`

All modules extend `SharedMethods` to access `fetch_paginated_data` and `make_slack_api_call`.

## Configuration Pattern

```ruby
ImmosquareSlack.config do |config|
  config.slack_api_token_bot = ENV.fetch("slack_api_token_bot", nil)
end
```

For local development, create `config_dev.yml` in the root with `slack_api_token_bot` key.

## Key Implementation Details

- Pagination is handled automatically via cursor-based iteration in `fetch_paginated_data`
- If a channel doesn't exist, `post_message` falls back to the "general" channel (configurable)
- Notification types: `:channel`, `:here`, `:everyone`, `:all`, or an array of email addresses
- The gem uses HTTParty for HTTP requests and requires Ruby >= 3.2.6
