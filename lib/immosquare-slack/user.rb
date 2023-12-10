module ImmosquareSlack
  module User
    extend SharedMethods
    class << self


      def list_users
        fetch_paginated_data("https://slack.com/api/users.list", "members")
      end

    end
  end
end
