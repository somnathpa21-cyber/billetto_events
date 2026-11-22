module Voting
  def self.subscriptions
    [
      [
        VoteProjector.new,
        [
          Events::EventLiked,
          Events::EventDisliked
        ]
      ]
    ]
  end
end