
module Voting
  class VoteProjector
    def call(event)
      data = event.data.stringify_keys

      vote =
        case event
        when Events::EventLiked
          "like"
        when Events::EventDisliked
          "dislike"
        else
          raise ArgumentError, "Unsupported event: #{event.class}"
        end

      now = Time.current

      EventVote.upsert(
        {
          event_id: data.fetch("event_id"),
          user_id: data.fetch("user_id"),
          vote: vote,
          created_at: now,
          updated_at: now
        },
        unique_by: :index_event_votes_on_event_id_and_user_id
      )
    end
  end
end
