
require "rails_helper"

RSpec.describe Voting::Handlers::LikeEventHandler do
  let(:handler) { described_class.new }
  let(:command) do
    Voting::LikeEvent.new(
      event_id: "event-123",
      user_id: "user-123"
    )
  end
  let(:service) { instance_double(Voting::VoteService) }

  before do
    allow(Voting::VoteService)
      .to receive(:new)
      .and_return(service)
  end

  describe "#handle" do
    it "delegates to VoteService with the like vote type" do
      expect(service).to receive(:call).with(
        event_id: "event-123",
        user_id: "user-123",
        vote: "like"
      ).and_return(:result)

      expect(handler.handle(command)).to eq(:result)
    end
  end
end
