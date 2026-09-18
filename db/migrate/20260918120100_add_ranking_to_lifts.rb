class AddRankingToLifts < ActiveRecord::Migration[8.1]
  def up
    add_column :lifts, :score, :decimal, precision: 10, scale: 2
    add_column :lifts, :status, :string, null: false, default: "approved"
    add_index :lifts, [ :user_id, :exercise, :score ]
    add_index :lifts, :status

    # Score existing lifts on the new per-lift scales. Anything that now ranks
    # diamond or above goes to the review queue, like a newly logged lift would.
    Lift.reset_column_information
    Lift.includes(:user).find_each(&:rescore!)
  end

  def down
    remove_index :lifts, :status
    remove_index :lifts, [ :user_id, :exercise, :score ]
    remove_column :lifts, :status
    remove_column :lifts, :score
  end
end
