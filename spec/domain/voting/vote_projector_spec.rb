
require "rails_helper"

RSpec.describe Voting::VoteProjector do
  subject(:projector) { described_class.new }

  let(:event_id) { "event-123" }
  let(:user_id) { "user-456" }

  describe "#call" do
    it "creates a like vote when EventLiked is received" do
      event = Events::EventLiked.strict(
        data: {
          event_id: event_id,
          user_id: user_id
        }
      )

      projector.call(event)

      expect(
        EventVote.find_by(event_id: event_id, user_id: user_id).vote
      ).to eq("like")
    end

    it "creates a dislike vote when EventDisliked is received" do
      event = Events::EventDisliked.strict(
        data: {
          event_id: event_id,
          user_id: user_id
        }
      )

      projector.call(event)

      expect(
        EventVote.find_by(event_id: event_id, user_id: user_id).vote
      ).to eq("dislike")
    end

    it "updates the current vote when a user changes their vote" do
      liked_event = Events::EventLiked.strict(
        data: { event_id: event_id, user_id: user_id }
      )

      disliked_event = Events::EventDisliked.strict(
        data: { event_id: event_id, user_id: user_id }
      )

      projector.call(liked_event)
      projector.call(disliked_event)

      expect(EventVote.where(event_id: event_id, user_id: user_id).count)
        .to eq(1)

      expect(
        EventVote.find_by(event_id: event_id, user_id: user_id).vote
      ).to eq("dislike")
    end

    it "does not create duplicate records when an event is processed twice" do
      event = Events::EventLiked.strict(
        data: { event_id: event_id, user_id: user_id }
      )

      projector.call(event)
      projector.call(event)

      expect(EventVote.where(event_id: event_id, user_id: user_id).count)
        .to eq(1)
    end
  end
end
