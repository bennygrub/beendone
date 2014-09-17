class CreateAirports < ActiveRecord::Migration
  def change
    create_table :airports do |t|
      t.string :name
      t.string :city
      t.string :country
      t.string :faa
      t.string :icao
      t.float :latitude
      t.float :longitude
      t.integer :altitude
      t.integer :timezone
      t.string :dst

      t.timestamps
    end
  end
end
