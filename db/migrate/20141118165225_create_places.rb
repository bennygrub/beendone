class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.integer :trip_id
      t.integer :user_id
      t.string :location

      t.timestamps
    end
  end
end
