class UpdateUsersForWeightLog < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :bodyweight, :decimal
    add_column :users, :weight_unit, :integer, null: false, default: 0
    change_column_null :users, :sex, false, 1
  end
end
