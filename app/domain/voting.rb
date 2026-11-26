
module Voting
  def self.subscriptions
    projector = VoteProjector.new

    [
      [projector, Events::EventLiked],
      [projector, Events::EventDisliked]
    ]
  end
end
