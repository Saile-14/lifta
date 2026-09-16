class CreateBodyweightEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :bodyweight_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :kilograms, null: false
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :bodyweight_entries, %i[user_id recorded_at]
  end
end
