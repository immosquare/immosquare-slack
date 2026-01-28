# immosquare-slack

Ruby gem pour l'API Slack : poster des messages, lister les channels et les utilisateurs.

## Commandes

```bash
bundle install
bundle exec rake immosquare_slack:sample:post_message  # requiert config_dev.yml
```

## Architecture

Namespace `ImmosquareSlack` avec modules qui étendent `SharedMethods` :

| Module | Rôle |
|--------|------|
| Configuration | Stocke `slack_api_token_bot` |
| SharedMethods | HTTP (HTTParty), pagination, appels API |
| Channel | `list_channels`, `post_message` |
| User | `list_users` |

## Configuration

```ruby
ImmosquareSlack.config do |config|
  config.slack_api_token_bot = ENV.fetch("slack_api_token_bot", nil)
end
```

Dev local : créer `config_dev.yml` avec clé `slack_api_token_bot`.

## Notes

- Pagination cursor-based automatique via `fetch_paginated_data`
- Fallback vers "general" si le channel n'existe pas
- Notification types : `:channel`, `:here`, `:everyone`, `:all`, ou array d'emails
- Ruby >= 3.2.6
