
require "rails_helper"

RSpec.describe "Rails Event Store configuration" do
  it "configures a JSON event store client" do
    expect(Rails.configuration.event_store)
      .to be_a(RailsEventStore::JSONClient)
  end

  it "supports publishing events" do
    expect(Rails.configuration.event_store)
      .to respond_to(:publish)
  end

  it "supports reading events" do
    expect(Rails.configuration.event_store)
      .to respond_to(:read)
  end
end
