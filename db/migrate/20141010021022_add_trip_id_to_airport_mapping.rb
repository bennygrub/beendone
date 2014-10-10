class AddTripIdToAirportMapping < ActiveRecord::Migration
  def change
    add_column :airport_mappings, :trip_id, :integer
  end
end
