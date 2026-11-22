
class EventVote < ApplicationRecord
  VOTE_TYPES = %w[like dislike].freeze

  validates :event_id, :user_id, presence: true
  validates :vote, inclusion: { in: VOTE_TYPES }

  scope :likes, -> { where(vote: "like") }
  scope :dislikes, -> { where(vote: "dislike") }

  def self.totals_for(event_id)
    counts = where(event_id: event_id).group(:vote).count

    {
      likes: counts.fetch("like", 0),
      dislikes: counts.fetch("dislike", 0)
    }
  end

  def self.current_vote(event_id:, user_id:)
    find_by(event_id: event_id, user_id: user_id)&.vote
  end
end
