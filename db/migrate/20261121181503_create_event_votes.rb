
class CreateEventVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_votes do |t|
      t.string :event_id, null: false
      t.string :user_id, null: false
      t.string :vote, null: false

      t.timestamps
    end

    add_index :event_votes,
              [:event_id, :user_id],
              unique: true

    add_index :event_votes, [:event_id, :vote]
  end
end
