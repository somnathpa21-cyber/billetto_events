
require "rails_helper"
require "securerandom"

RSpec.describe Voting::VoteService do
  let(:event_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }
  let(:event_store) { Rails.configuration.event_store }
  let(:service) { described_class.new }

  before do
    Event.create!(
      billetto_id: event_id,
      title: "Test Event",
      starts_at: 1.day.from_now
    )
  end

  describe "#call" do
    shared_examples "a vote" do
      it "publishes the expected event" do
        result = service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        expect(result).to be_a(expected_event_class)
        expect(result.data).to include(
          event_id: event_id,
          user_id: user_id
        )
      end

      it "publishes to the event stream" do
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        events = event_store.read
          .stream("Event$#{event_id}")
          .to_a

        expect(events.map(&:event_type))
          .to include(expected_event_class.name)
      end

      it "links the event to the user stream" do
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        events = event_store.read
          .stream("User$#{user_id}")
          .to_a

        expect(events.map(&:event_type))
          .to include(expected_event_class.name)
      end

      it "updates the current vote" do
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        expect(
          EventVote.current_vote(
            event_id: event_id,
            user_id: user_id
          )
        ).to eq(vote)
      end

      it "does not publish another event for the same vote" do
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        expect {
          service.call(
            event_id: event_id,
            user_id: user_id,
            vote: vote
          )
        }.not_to change {
          event_store.read
            .stream("Event$#{event_id}")
            .to_a.size
        }
      end

      it "allows switching from the opposite vote" do
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: opposite_vote
        )

        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: vote
        )

        expect(
          EventVote.current_vote(
            event_id: event_id,
            user_id: user_id
          )
        ).to eq(vote)

        events = event_store.read
          .stream("Event$#{event_id}")
          .to_a

        expect(events.map(&:event_type)).to include(
          expected_event_class.name,
          opposite_event_class.name
        )
      end
    end

    context "when voting like" do
      let(:vote) { "like" }
      let(:opposite_vote) { "dislike" }
      let(:expected_event_class) { Events::EventLiked }
      let(:opposite_event_class) { Events::EventDisliked }

      it_behaves_like "a vote"
    end

    context "when voting dislike" do
      let(:vote) { "dislike" }
      let(:opposite_vote) { "like" }
      let(:expected_event_class) { Events::EventDisliked }
      let(:opposite_event_class) { Events::EventLiked }

      it_behaves_like "a vote"
    end

    it "raises an error when the event does not exist" do
      expect {
        service.call(
          event_id: "non-existent-event",
          user_id: user_id,
          vote: "like"
        )
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error for an invalid vote type" do
      expect {
        service.call(
          event_id: event_id,
          user_id: user_id,
          vote: "maybe"
        )
      }.to raise_error(
        ArgumentError,
        "Invalid vote type: maybe"
      )
    end
  end
end
