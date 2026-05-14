class AddCountToLifts < ActiveRecord::Migration[8.1]
  def change
    add_column :lifts, :count, :integer, default: 0
  end
end
