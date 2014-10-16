class Airport < ActiveRecord::Base
  require 'csv'

  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

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
