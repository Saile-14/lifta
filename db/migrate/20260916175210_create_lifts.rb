class CreateLifts < ActiveRecord::Migration[8.1]
  def change
    create_table :lifts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :exercise
      t.decimal :weight_lifted
      t.integer :reps
      t.date :lifted_at

      t.timestamps
    end
  end
end
