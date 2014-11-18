class CreateHighlights < ActiveRecord::Migration
  def change
    create_table :highlights do |t|
      t.integer :user_id
      t.integer :trip_id
      t.integer :category_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
