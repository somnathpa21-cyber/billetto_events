require "rails_helper"
require "securerandom"

RSpec.describe "Voting event subscriptions" do
  let(:event_store) { Rails.configuration.event_store }

  it "updates the vote read model when an event is published" do
    event_id = SecureRandom.uuid
    user_id = SecureRandom.uuid

    event = Events::EventLiked.strict(
      data: {
        event_id: event_id,
        user_id: user_id
      }
    )

    expect {
      event_store.publish(
        event,
        stream_name: event.stream_names.first
      )
    }.to change {
      EventVote.where(
        event_id: event_id,
        user_id: user_id,
        vote: "like"
      ).count
    }.from(0).to(1)
  end
end