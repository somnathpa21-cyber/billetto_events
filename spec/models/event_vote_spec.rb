
require "rails_helper"

RSpec.describe EventVote do
  describe "validations" do
    it "requires event_id, user_id and vote" do
      vote = described_class.new

      expect(vote).not_to be_valid
      expect(vote.errors.attribute_names)
        .to include(:event_id, :user_id, :vote)
    end

    it "accepts like as a vote" do
      vote = described_class.new(
        event_id: "event-123",
        user_id: "user-123",
        vote: "like"
      )

      expect(vote).to be_valid
    end

    it "accepts dislike as a vote" do
      vote = described_class.new(
        event_id: "event-123",
        user_id: "user-123",
        vote: "dislike"
      )

      expect(vote).to be_valid
    end

    it "rejects an invalid vote type" do
      vote = described_class.new(
        event_id: "event-123",
        user_id: "user-123",
        vote: "neutral"
      )

      expect(vote).not_to be_valid
    end
  end

  describe ".totals_for" do
    it "returns the current like and dislike totals" do
      described_class.create!(
        event_id: "event-123",
        user_id: "user-1",
        vote: "like"
      )

      described_class.create!(
        event_id: "event-123",
        user_id: "user-2",
        vote: "like"
      )

      described_class.create!(
        event_id: "event-123",
        user_id: "user-3",
        vote: "dislike"
      )

      expect(described_class.totals_for("event-123")).to eq(
        likes: 2,
        dislikes: 1
      )
    end
  end

  describe ".current_vote" do
    it "returns the user's current vote" do
      described_class.create!(
        event_id: "event-123",
        user_id: "user-1",
        vote: "like"
      )

      expect(
        described_class.current_vote(
          event_id: "event-123",
          user_id: "user-1"
        )
      ).to eq("like")
    end
  end
end
