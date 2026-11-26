
module Voting
  module Handlers
    class DislikeEventHandler
      include Command::Handler

      handles Voting::DislikeEvent, :handle

      def handle(command)
        Voting::VoteService.new.call(
          event_id: command.event_id,
          user_id: command.user_id,
          vote: "dislike"
        )
      end
    end
  end
end
