
require "rails_helper"

class FactSpecEvent < Fact
  SCHEMA = {
    event_id: Integer,
    user_id: String
  }.freeze

  def stream_names
    ["TestEvent$#{data.fetch(:event_id)}"]
  end
end

class FactSpecEventWithoutStreams < Fact
  SCHEMA = {}.freeze
end

RSpec.describe Fact do
  describe ".strict" do
    it "creates an event with valid data" do
      event = FactSpecEvent.strict(
        data: {
          event_id: 100,
          user_id: "user_101"
        }
      )

      expect(event.data[:event_id]).to eq(100)
      expect(event.data[:user_id]).to eq("user_101")
    end

    it "accepts string keys and normalizes them" do
      event = FactSpecEvent.strict(
        data: {
          "event_id" => 100,
          "user_id" => "user_101"
        }
      )

      expect(event.data[:event_id]).to eq(100)
    end

    it "rejects missing attributes" do
      expect {
        FactSpecEvent.strict(data: { event_id: 100 })
      }.to raise_error(Fact::InvalidSchema, /Missing keys/)
    end

    it "rejects unexpected attributes" do
      expect {
        FactSpecEvent.strict(
          data: {
            event_id: 100,
            user_id: "user_101",
            extra: "value"
          }
        )
      }.to raise_error(Fact::InvalidSchema, /unknown keys/)
    end

    it "rejects incorrect attribute types" do
      expect {
        FactSpecEvent.strict(
          data: {
            event_id: "100",
            user_id: "user_101"
          }
        )
      }.to raise_error(Fact::InvalidSchema, /event_id must be a Integer/)
    end
  end

  describe "#stream_names" do
    it "returns the stream names defined by the event" do
      event = FactSpecEvent.strict(
        data: {
          event_id: 100,
          user_id: "user_101"
        }
      )

      expect(event.stream_names).to eq(["TestEvent$100"])
    end

    it "raises when a subclass does not implement stream_names" do
      event = FactSpecEventWithoutStreams.new(data: {})

      expect {
        event.stream_names
      }.to raise_error(NotImplementedError)
    end
  end
end
