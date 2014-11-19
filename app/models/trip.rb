class Trip < ActiveRecord::Base
	belongs_to :user
	has_many :flights
	has_many :highlights
	has_many :mates
	has_many :places
	accepts_nested_attributes_for :highlights
	accepts_nested_attributes_for :mates
	accepts_nested_attributes_for :flights
	has_attached_file :cover, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/user.png"
  	validates_attachment_content_type :cover, :content_type => /\Aimage\/.*\Z/
  	
end
