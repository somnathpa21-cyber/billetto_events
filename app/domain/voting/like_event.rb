
module Voting
  class LikeEvent
    include Command::Executable
    include EventStoreInjector

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true

    def call
      validate!
      
      event = Events::EventLiked.strict(
        data: {
          event_id: event_id,
          user_id: user_id
        }
      )

      event_store.publish(
        event,
        stream_name: event.stream_names.first
      )

      event_store.link(
        [event.event_id],
        stream_name: event.stream_names.last
      )

      event
    end
  end
end
