
module Voting
  class VoteService
    include EventStoreInjector

    VOTE_CONFIG = {
      "like" => Events::EventLiked,
      "dislike" => Events::EventDisliked
    }.freeze

    def call(event_id:, user_id:, vote:)
      event_class = VOTE_CONFIG.fetch(vote) do
        raise ArgumentError, "Invalid vote type: #{vote}"
      end

      Event.transaction do
        # Serialize voting operations for the same event.
        Event.lock.find_by!(billetto_id: event_id)

        current_vote = EventVote.current_vote(
          event_id: event_id,
          user_id: user_id
        )

        # Repeating the same vote should not publish another event.
        unless current_vote == vote
          publish_vote(event_class, event_id, user_id)
        end
      end
    end

    private

    def publish_vote(event_class, event_id, user_id)
      event = event_class.strict(
        data: {
          event_id: event_id,
          user_id: user_id
        }
      )

      event_store.publish(
        event,
        stream_name: event.stream_names.first
      )

      event_store.link(
        [event.event_id],
        stream_name: event.stream_names.last
      )

      event
    end
  end
end
