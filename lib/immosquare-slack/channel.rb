module ImmosquareSlack
  module Channel
    extend SharedMethods

    GENERAL_CHANNEL = "general".freeze

    class << self

      ##============================================================##
      ## Fetches the list of channels (public + private, including
      ## archived), memoized per process for the lifetime of that
      ## process (a Puma worker or Sidekiq runs for hours/days).
      ##
      ## Piège : le cache ne reflète que l'état du workspace au
      ## premier appel. Un channel créé ou renommé ensuite n'y est
      ## pas. `force: true` vide le cache et refetch — à utiliser sur
      ## un miss de lookup pour distinguer un channel réellement
      ## absent d'un cache périmé avant tout fallback.
      ##============================================================##
      def list_channels(force: false)
        @list_channels = nil if force
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
      ##
      ## Slack only notifies a mention to members of the channel the
      ## message lands in. When `notify` is an Array of emails, the
      ## mentioned users outside that channel (all of them when the
      ## message falls back to the general channel) also receive it
      ## as a direct message from the bot, unless
      ## `direct_message_unreachable_mentions` is disabled.
      ##============================================================##
      def post_message(text, channel_name: nil, notify: nil, notify_text: nil, bot_name: nil, notify_general_if_invalid_channel: true)
        channel_name ||= ImmosquareSlack.configuration.default_channel
        bot_name     ||= ImmosquareSlack.configuration.default_bot_name

        raise(ArgumentError, "channel_name is required (or set ImmosquareSlack.configuration.default_channel)") if channel_name.nil?

        ##============================================================##
        ## A miss can mean the channel really doesn't exist, or that
        ## the memoized list predates its creation. Retry once on a
        ## freshly fetched list before declaring it missing.
        ##============================================================##
        channel_id        = get_channel_id_by_name(channel_name)
        channel_id        = get_channel_id_by_name(channel_name, :force => true) if channel_id.nil?
        mentioned_members = notify.is_a?(Array) ? members_with_emails(notify) : []

        if channel_id.nil?
          raise("channel '#{channel_name}' not found on slack") if channel_name == GENERAL_CHANNEL || !notify_general_if_invalid_channel

          direct_message_unreachable_members(mentioned_members, nil, "Mentioned in *##{channel_name}* (channel not found):\n#{text}", bot_name)
          text = "immosquare-slack missing channel *#{channel_name}*\nmessage:\n#{text}"
          return post_message(text, :channel_name => GENERAL_CHANNEL, :notify => :channel, :notify_text => "", :bot_name => bot_name, :notify_general_if_invalid_channel => false)
        end

        notification_text = notify ? build_notification_text(channel_id, notify, mentioned_members, *notify_text) : nil
        response          = send_message(channel_id, "#{notification_text}#{text}", bot_name)
        direct_message_unreachable_members(mentioned_members, channel_id, "Mentioned in <##{channel_id}>:\n#{text}", bot_name)
        response
      end

      private

      ##============================================================##
      ## Resolves a channel id from its name. "general" is matched
      ## via the `is_general` flag because workspaces can rename
      ## their general channel.
      ##============================================================##
      def get_channel_id_by_name(channel_name, force: false)
        channels = list_channels(:force => force)
        channel  = channels.find do |c|
          if channel_name == GENERAL_CHANNEL
            c["is_general"]
          else
            c["name"] == channel_name && c["is_archived"] == false
          end
        end
        channel&.[]("id")
      end

      ##============================================================##
      ## Fetches the list of members of a channel.
      ##============================================================##
      def get_channel_members(channel_id)
        fetch_paginated_data("https://slack.com/api/conversations.members", "members", {:channel => channel_id})
      end

      ##============================================================##
      ## Posts `text` to a conversation: a channel id, or a user id
      ## for a direct message from the bot.
      ##============================================================##
      def send_message(conversation_id, text, bot_name)
        body = {
          :channel => conversation_id,
          :text    => text
        }

        body[:username] = bot_name if bot_name

        make_slack_api_call("https://slack.com/api/chat.postMessage", :method => :post, :body => body)
      end

      ##============================================================##
      ## Active workspace members whose `profile.email` is in
      ## `emails`. Without the `users:read.email` scope no profile
      ## carries an email, so nobody matches.
      ##
      ## Piège : `users.list` renvoie aussi les comptes désactivés,
      ## qui gardent leur email mais ne peuvent recevoir aucun DM.
      ##============================================================##
      def members_with_emails(emails)
        ImmosquareSlack::User.list_users.select {|m| !m["deleted"] && emails.include?(m.dig("profile", "email")) }
      end

      ##============================================================##
      ## Sends `text` as a direct message to the mentioned members who
      ## are not in the channel (`channel_id` nil: none of them is
      ## reachable), since Slack would not notify them.
      ##
      ## Best effort : un DM refusé par Slack est ignoré. Le laisser
      ## remonter ferait échouer `post_message` après le post dans le
      ## channel (doublon au retry de l'appelant) ou avant le repli
      ## sur general (message perdu).
      ##============================================================##
      def direct_message_unreachable_members(mentioned_members, channel_id, text, bot_name)
        return if mentioned_members.empty? || !ImmosquareSlack.configuration.direct_message_unreachable_mentions

        channel_member_ids = channel_id ? get_channel_members(channel_id) : []
        mentioned_members.reject {|m| channel_member_ids.include?(m["id"]) }.each do |member|
          send_message(member["id"], text, bot_name)
        rescue RuntimeError
          next
        end
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
      def build_notification_text(channel_id, notify, mentioned_members, text = "Hello")
        final =
          if notify.is_a?(Array)
            mentioned_members.map {|m| "<@#{m["id"]}>" }.join(", ")
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
