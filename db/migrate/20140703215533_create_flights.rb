class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.integer :trip_id
      t.integer :airline_id
      t.datetime :depart_airport
      t.datetime :depart_time
      t.datetime :arrival_airport
      t.datetime :arrival_time
      t.text :seat_type

      t.timestamps
    end
  end
end
