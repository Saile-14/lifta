class AddBodyweightAndSexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bodyweight, :decimal
    add_column :users, :sex, :integer
  end
end
