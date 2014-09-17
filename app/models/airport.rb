class Airport < ActiveRecord::Base
  require 'csv'

  def self.import(file)
    CSV.foreach("/airports.csv", headers: true) do |row|

      airpot_hash = row.to_hash # exclude the price field
      airport = Airport.where(name: airport_hash["name"])

      if airport.count == 1
        airport.first.update_attributes(airport_hash)
      else
        Airport.create!(airport_hash)
      end # end if !airport.nil?
    end # end CSV.foreach
  end # end self.import(file)

end
