class UpdateLiftsForBodyweightSnapshot < ActiveRecord::Migration[8.1]
  def change
    add_column :lifts, :bodyweight_kg, :decimal
  end
end
