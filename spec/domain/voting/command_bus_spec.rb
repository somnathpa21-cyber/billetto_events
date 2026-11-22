
require "rails_helper"
require "securerandom"
require Rails.root.join("lib/command")

RSpec.describe "Voting command bus integration" do
  let(:event_store) { Rails.configuration.event_store }
  let(:command_bus) { Rails.configuration.command_bus }

  it "executes a like command through the command bus" do
    event_id = SecureRandom.uuid
    user_id = SecureRandom.uuid

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

    user_events = event_store
      .read
      .stream("User$#{user_id}")
      .to_a

    expect(user_events.map(&:event_type))
      .to include("Events::EventLiked")
  end

  it "executes a dislike command through the command bus" do
    event_id = SecureRandom.uuid
    user_id = SecureRandom.uuid

    command = Voting::DislikeEvent.new(
      event_id: event_id,
      user_id: user_id
    )

    expect {
      command_bus.call(command)
    }.to change {
      event_store.read.stream("Event$#{event_id}").to_a.size
    }.by(1)

    user_events = event_store
      .read
      .stream("User$#{user_id}")
      .to_a

    expect(user_events.map(&:event_type))
      .to include("Events::EventDisliked")
  end
end
