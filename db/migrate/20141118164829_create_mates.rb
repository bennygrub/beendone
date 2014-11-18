class CreateMates < ActiveRecord::Migration
  def change
    create_table :mates do |t|
      t.integer :trip_id
      t.string :email
      t.string :name

      t.timestamps
    end
  end
end
