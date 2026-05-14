class AddSeshCountToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sesh_count, :integer, default: 0
  end
end
