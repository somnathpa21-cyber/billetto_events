
require "rails_helper"

RSpec.describe Event, type: :model do
  subject(:event) do
    described_class.new(
      billetto_id: "2099841",
      title: "NADA cafe",
      description: "A test event",
      url: "https://billetto.dk/e/test",
      image_url: "https://example.com/image.jpg",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(event).to be_valid
    end

    it "requires billetto_id" do
      event.billetto_id = nil

      expect(event).not_to be_valid
      expect(event.errors[:billetto_id]).to include("can't be blank")
    end

    it "requires a unique billetto_id" do
      event.save!

      duplicate_event = described_class.new(
        billetto_id: event.billetto_id,
        title: "Another event",
        starts_at: 3.days.from_now
      )

      expect(duplicate_event).not_to be_valid
      expect(duplicate_event.errors[:billetto_id]).to include("has already been taken")
    end

    it "requires title" do
      event.title = nil

      expect(event).not_to be_valid
      expect(event.errors[:title]).to include("can't be blank")
    end

    it "requires starts_at" do
      event.starts_at = nil

      expect(event).not_to be_valid
      expect(event.errors[:starts_at]).to include("can't be blank")
    end
  end

  describe "scopes" do
    let!(:upcoming_event) do
      described_class.create!(
        billetto_id: "upcoming-1",
        title: "Upcoming event",
        starts_at: 2.days.from_now
      )
    end

    let!(:past_event) do
      described_class.create!(
        billetto_id: "past-1",
        title: "Past event",
        starts_at: 2.days.ago
      )
    end

    it "returns upcoming events" do
      expect(described_class.upcoming).to include(upcoming_event)
      expect(described_class.upcoming).not_to include(past_event)
    end

    it "returns past events" do
      expect(described_class.past).to include(past_event)
      expect(described_class.past).not_to include(upcoming_event)
    end
  end
end
