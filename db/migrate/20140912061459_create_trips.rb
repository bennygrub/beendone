class CreateTrips < ActiveRecord::Migration
  def change
    create_table :trips do |t|
      t.integer :user_id
      t.string :name

      t.timestamps
    end
  end
end
