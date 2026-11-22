
class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :billetto_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :url
      t.string :image_url
      t.datetime :starts_at, null: false
      t.datetime :ends_at

      t.timestamps
    end

    add_index :events, :billetto_id, unique: true
    add_index :events, :starts_at
  end
end
