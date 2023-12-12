module ImmosquareSlack
  module Channel
    extend SharedMethods
    class << self

      ##============================================================##
      ## Pour récupérer la liste des channels
      ##============================================================##
      def list_channels
        fetch_paginated_data("https://slack.com/api/conversations.list", "channels")
      end

      ##============================================================##
      ## Pour poster un message dans un channel
      ##============================================================##
      def post_message(channel_name, text, notify: nil, notify_text: nil, bot_name: nil)
        channel_id = get_channel_id_by_name(channel_name)
        raise("Channel not found") if channel_id.nil?

        url               = "https://slack.com/api/chat.postMessage"
        notification_text = notify ? build_notification_text(channel_id, notify, notify_text) : nil
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
      ## Pour récupérer l'id d'un channel en fonction de son nom
      ##============================================================##
      def get_channel_id_by_name(channel_name)
        channels = list_channels
        channel = channels.find {|c| c["name"] == channel_name }
        channel ? channel["id"] : nil
      end

      ##============================================================##
      ## Pour récupérer la liste des membres d'un channel
      ##============================================================##
      def get_channel_members(channel_id)
        fetch_paginated_data("https://slack.com/api/conversations.members", "members", {:channel => channel_id})
      end

      ##============================================================##
      ## Méthode récupérant les membres d'un channel et les notifier
      ## sur le message
      ## on ne peut pas utilser in? si on veut que la gem soit
      ## compatible avec ruby (sans rails)
      ## pareil pour present?
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


        "#{text} #{final}\n" if !final.to_s.empty?
      end

    end
  end
end
