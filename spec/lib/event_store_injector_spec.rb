
require "rails_helper"

RSpec.describe EventStoreInjector do
  let(:test_class) do
    Class.new do
      include EventStoreInjector
    end
  end

  it "provides access to the configured event store" do
    object = test_class.new

    expect(object.event_store)
      .to equal(Rails.configuration.event_store)
  end
end
