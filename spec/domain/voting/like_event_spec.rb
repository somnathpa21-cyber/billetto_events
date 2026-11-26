
require "rails_helper"

RSpec.describe Voting::LikeEvent do
  describe "validations" do
    it "is valid with event_id and user_id" do
      command = described_class.new(
        event_id: "event-123",
        user_id: "user-123"
      )

      expect(command).to be_valid
    end

    it "is invalid without event_id" do
      command = described_class.new(user_id: "user-123")

      expect(command).not_to be_valid
      expect(command.errors[:event_id]).to include("can't be blank")
    end

    it "is invalid without user_id" do
      command = described_class.new(event_id: "event-123")

      expect(command).not_to be_valid
      expect(command.errors[:user_id]).to include("can't be blank")
    end

    it "is invalid without both attributes" do
      command = described_class.new

      expect(command).not_to be_valid
      expect(command.errors[:event_id]).to include("can't be blank")
      expect(command.errors[:user_id]).to include("can't be blank")
    end
  end
end
