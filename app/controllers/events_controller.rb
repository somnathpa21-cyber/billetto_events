class EventsController < ApplicationController
  def index
    @events = Event.upcoming.limit(50)

    event_ids = @events.map(&:billetto_id)

    @vote_totals = EventVote
      .where(event_id: event_ids)
      .group(:event_id, :vote)
      .count

    @current_votes = if clerk_signed_in?
      EventVote
        .where(event_id: event_ids, user_id: clerk.user_id)
        .index_by(&:event_id)
    else
      {}
    end
  end
end