
class ApplicationSubscriptions
  def initialize(event_store:)
    @event_store = event_store
  end

  def register
    Voting.subscriptions.each do |subscriber, event_class|
      event_store.subscribe(subscriber, to: [event_class])
    end
  end

  private

  attr_reader :event_store
end
