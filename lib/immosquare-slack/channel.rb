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
      def post_message(channel_name, text, notify: false, bot_name: nil)
        channel_id = get_channel_id_by_name(channel_name)
        raise("Channel not found") if channel_id.nil?


        url  = "https://slack.com/api/chat.postMessage"
        body = {
          :channel  => channel_id,
          :text     => "#{build_notification_text(channel_id) if notify}#{text}",
          :username => bot_name.presence
        }
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
      ##============================================================##
      def build_notification_text(channel_id, text = "Hello")
        members = get_channel_members(channel_id)
        members = member_mentions = members.map {|member_id| "<@#{member_id}>" }
        "#{text} #{member_mentions.join(", ")}\n"
      end

    end
  end
end
