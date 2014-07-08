class ChangeDateFormatInFlights < ActiveRecord::Migration
  def change
  	change_column :flights, :depart_time, :datetime
  	change_column :flights, :arrival_time, :datetime
  end
end
