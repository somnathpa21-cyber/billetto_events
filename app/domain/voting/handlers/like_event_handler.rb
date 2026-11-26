
module Voting
  module Handlers
    class LikeEventHandler
      include Command::Handler

      handles Voting::LikeEvent, :handle

      def handle(command)
        Voting::VoteService.new.call(
          event_id: command.event_id,
          user_id: command.user_id,
          vote: "like"
        )
      end
    end
  end
end
