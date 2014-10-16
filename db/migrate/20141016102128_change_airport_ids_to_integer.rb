class ChangeAirportIdsToInteger < ActiveRecord::Migration
  def change
  	change_column :flights, :arrival_airport, 'integer USING CAST(column_name AS integer)'
  	change_column :flights, :depart_airport, 'integer USING CAST(column_name AS integer)'
  end
end
