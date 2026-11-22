class VotingController < ApplicationController
  before_action :require_clerk_session!
  before_action :set_event

  def like
    command = Voting::LikeEvent.new(
      event_id: @event.billetto_id,
      user_id: clerk.user_id
    )

    Rails.configuration.command_bus.call(command)

    redirect_to events_path, notice: "You liked this event."
  end

  def dislike
    command = Voting::DislikeEvent.new(
      event_id: @event.billetto_id,
      user_id: clerk.user_id
    )

    Rails.configuration.command_bus.call(command)

    redirect_to events_path, notice: "You disliked this event."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
