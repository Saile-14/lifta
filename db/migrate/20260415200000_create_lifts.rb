class CreateLifts < ActiveRecord::Migration[8.1]
  def change
    create_table :lifts do |t|
      t.string :name

      t.timestamps
    end
  end
end
