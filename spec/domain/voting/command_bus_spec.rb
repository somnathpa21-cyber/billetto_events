require "rails_helper"
require "securerandom"
require Rails.root.join("lib/command")

RSpec.describe "Voting command bus integration" do
  let(:event_store) { Rails.configuration.event_store }
  let(:command_bus) { Rails.configuration.command_bus }

  let(:event_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }

  before do
    Event.create!(
      billetto_id: event_id,
      title: "Test Event",
      starts_at: 1.day.from_now
    )
  end

  it "executes a like command through the command bus" do
    command = Voting::LikeEvent.new(
      event_id: event_id,
      user_id: user_id
    )

    expect(command_bus).to be_a(Command::Bus)

    expect {
      command_bus.call(command)
    }.to change {
      event_store.read.stream("Event$#{event_id}").to_a.size
    }.by(1)

    expect(EventVote.current_vote(
      event_id: event_id,
      user_id: user_id
    )).to eq("like")

    user_events = event_store.read.stream("User$#{user_id}").to_a

    expect(user_events.map(&:event_type))
      .to include("Events::EventLiked")
  end

  it "executes a dislike command through the command bus" do
    command = Voting::DislikeEvent.new(
      event_id: event_id,
      user_id: user_id
    )

    expect {
      command_bus.call(command)
    }.to change {
      event_store.read.stream("Event$#{event_id}").to_a.size
    }.by(1)

    expect(EventVote.current_vote(
      event_id: event_id,
      user_id: user_id
    )).to eq("dislike")

    user_events = event_store.read.stream("User$#{user_id}").to_a

    expect(user_events.map(&:event_type))
      .to include("Events::EventDisliked")
  end
end