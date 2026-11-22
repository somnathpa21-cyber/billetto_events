
require "rails_helper"

RSpec.describe Voting::DislikeEvent do
  let(:command) do
    described_class.new(
      event_id: "event-789",
      user_id: "user-456"
    )
  end

  describe "#call" do
    it "publishes an EventDisliked event" do
      result = command.call

      expect(result).to be_a(Events::EventDisliked)
      expect(result.data).to include(
        event_id: "event-789",
        user_id: "user-456"
      )
    end

    it "publishes to the event stream" do
      command.call

      events = Rails.configuration.event_store
        .read
        .stream("Event$event-789")
        .to_a

      expect(events.map(&:event_type))
        .to include("Events::EventDisliked")
    end

    it "links the event to the user stream" do
      command.call

      events = Rails.configuration.event_store
        .read
        .stream("User$user-456")
        .to_a

      expect(events.map(&:event_type))
        .to include("Events::EventDisliked")
    end

    it "requires an event_id and user_id" do
      invalid_command = described_class.new

      expect { invalid_command.call }
        .to raise_error(ActiveModel::ValidationError)
    end
  end
end
