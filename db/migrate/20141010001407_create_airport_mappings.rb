class CreateAirportMappings < ActiveRecord::Migration
  def change
    create_table :airport_mappings do |t|
      t.string :name
      t.string :city
      t.integer :airport_id
      t.integer :airline_id
      t.string :message_id
      t.string :note

      t.timestamps
    end
  end
end
