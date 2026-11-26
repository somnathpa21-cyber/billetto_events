
module Voting
  class DislikeEvent
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true
  end
end
