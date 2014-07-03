class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.integer :trip_id
      t.integer :airline_id
      t.text :depart_airport
      t.date :depart_time
      t.text :arrival_airport
      t.date :arrival_time
      t.text :seat_type

      t.timestamps
    end
  end
end
