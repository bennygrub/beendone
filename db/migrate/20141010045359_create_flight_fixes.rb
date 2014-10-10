class CreateFlightFixes < ActiveRecord::Migration
  def change
    create_table :flight_fixes do |t|
      t.integer :airline_mapping_id
      t.integer :flight_id
      t.integer :direction
      t.boolean :status
      t.integer :trip_id

      t.timestamps
    end
  end
end
