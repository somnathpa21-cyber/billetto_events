
require "rails_helper"

RSpec.describe Events::EventDisliked do
  let(:event) do
    described_class.strict(
      data: {
        event_id: "billetto_500",
        user_id: "user_101"
      }
    )
  end

  it "creates an event with valid data" do
    expect(event.data[:event_id]).to eq("billetto_500")
    expect(event.data[:user_id]).to eq("user_101")
  end

  it "returns the event and user streams" do
    expect(event.stream_names).to eq(
      [
        "Event$billetto_500",
        "User$user_101"
      ]
    )
  end

  it "rejects missing user_id" do
    expect {
      described_class.strict(data: { event_id: "billetto_500" })
    }.to raise_error(Fact::InvalidSchema)
  end
end
