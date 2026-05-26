module ImmosquareSlack
  module Channel
    extend SharedMethods

    GENERAL_CHANNEL = "general".freeze

    class << self

      ##============================================================##
      ## Fetches the list of channels (public + private, including
      ## archived). Memoized per process — call sites that need a
      ## fresh list should reset @list_channels explicitly.
      ##============================================================##
      def list_channels
        @list_channels ||= begin
          extra_params = {
            :types            => ["public_channel", "private_channel"].join(","),
            :exclude_archived => false
          }
          fetch_paginated_data("https://slack.com/api/conversations.list", "channels", extra_params)
        end
      end

      ##============================================================##
      ## Posts a message to a channel.
      ##
      ## `channel_name` and `bot_name` are optional keyword args:
      ## if nil, they fall back to the global config
      ## `ImmosquareSlack.configuration.default_channel` and
      ## `default_bot_name`. Lets apps that always notify the same
      ## channel avoid repeating the value at every call site.
      ##
      ## If no channel can be resolved after fallback, raises an
      ## ArgumentError immediately (clearer than the cryptic error
      ## returned by the Slack API).
      ##============================================================##
      def post_message(text, channel_name: nil, notify: nil, notify_text: nil, bot_name: nil, notify_general_if_invalid_channel: true)
        channel_name ||= ImmosquareSlack.configuration.default_channel
        bot_name     ||= ImmosquareSlack.configuration.default_bot_name

        raise(ArgumentError, "channel_name is required (or set ImmosquareSlack.configuration.default_channel)") if channel_name.nil?

        channel_id = get_channel_id_by_name(channel_name)

        if channel_id.nil?
          text = "immosquare-slack missing channel *#{channel_name}*\nmessage:\n#{text}"
          return post_message(text, :channel_name => GENERAL_CHANNEL, :notify => :channel, :notify_text => "", :bot_name => bot_name, :notify_general_if_invalid_channel => false) if channel_name != GENERAL_CHANNEL && notify_general_if_invalid_channel

          raise("channel '#{channel_name}' not found on slack")
        end

        url               = "https://slack.com/api/chat.postMessage"
        notification_text = notify ? build_notification_text(channel_id, notify, *notify_text) : nil
        text              = "#{notification_text}#{text}"

        body = {
          :channel => channel_id,
          :text    => text
        }

        body[:username] = bot_name if bot_name

        make_slack_api_call(url, :method => :post, :body => body)
      end

      private

      ##============================================================##
      ## Resolves a channel id from its name. "general" is matched
      ## via the `is_general` flag because workspaces can rename
      ## their general channel.
      ##============================================================##
      def get_channel_id_by_name(channel_name)
        channels = list_channels
        channel  = channels.find do |c|
          if channel_name == GENERAL_CHANNEL
            c["is_general"]
          else
            c["name"] == channel_name && c["is_archived"] == false
          end
        end
        channel.nil? ? nil : channel["id"]
      end

      ##============================================================##
      ## Fetches the list of members of a channel.
      ##============================================================##
      def get_channel_members(channel_id)
        fetch_paginated_data("https://slack.com/api/conversations.members", "members", {:channel => channel_id})
      end

      ##============================================================##
      ## Builds the notification prefix prepended to the message
      ## body. `notify` may be:
      ##   - an Array of emails: mentions matching workspace members
      ##   - :all                : mentions every member of the channel
      ##   - :channel/:here/:everyone : Slack-wide broadcast tokens
      ##
      ## Note: avoids `in?` and `present?` so the gem stays usable
      ## from plain Ruby (no Rails / ActiveSupport required).
      ##============================================================##
      def build_notification_text(channel_id, notify, text = "Hello")
        final =
          if notify.is_a?(Array)
            members = ImmosquareSlack::User.list_users
            members = members.select {|m| notify.include?(m["profile"]["email"]) }
            members.map {|m| "<@#{m["id"]}>" }.join(", ")
          elsif notify.to_sym == :all
            members = get_channel_members(channel_id)
            members.map {|m| "<@#{m}>" }.join(", ")
          elsif notify.to_sym == :channel
            "<!channel>"
          elsif notify.to_sym == :here
            "<!here>"
          elsif notify.to_sym == :everyone
            "<!everyone>"
          end

        return nil if final.to_s.empty?

        text.empty? ? "#{final}\n" : "#{text} #{final}\n"
      end

    end
  end
end
