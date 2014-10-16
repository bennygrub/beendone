class ChangeAirportIdsToInteger < ActiveRecord::Migration
  def change
  	change_column :flights, :arrival_airport, :integer
  	change_column :flights, :depart_airport, :integer
  end
end
