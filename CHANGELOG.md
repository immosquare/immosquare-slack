## [0.2.1] - 2026-05-26
- Refetch the channel list once on a lookup miss before falling back, so a channel created after the process started is found instead of being misrouted to general

## [0.2.0] - 2026-05-26
- **BREAKING**: `Channel.post_message` now takes `text` as the only positional argument; `channel_name` becomes a keyword argument (`post_message(text, channel_name: ...)`)
- Add `default_channel` and `default_bot_name` configuration options, used as fallback when `channel_name` / `bot_name` are omitted
- Raise `ArgumentError` when no channel can be resolved (instead of a cryptic Slack API error)
- Fix leading space in the notification prefix when the prefix text is empty
- Use `public_send` instead of `send` for the HTTParty request dispatch

## [0.1.6] - 2024-12-11
- Add new param notify_general_if_invalid_channel (default: true) to notify general channel if the channel is invalid

## [0.1.5] - 2024-12-11
- Improve raise message

## [0.1.4] - 2023-12-12
- Fix notifcation_text

## [0.1.3] - 2023-12-12
- Fix bug with bot_name

## [0.1.2] - 2023-12-11
- Fix notifications options (@channel, @here, @everyone)

## [0.1.1] - 2023-12-11
- Improve notifications options

## [0.1.0] - 2023-12-10
- Initial release
