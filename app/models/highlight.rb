class Highlight < ActiveRecord::Base
	belongs_to :user
	belongs_to :trip
	validates_presence_of :name, :description, :category_id
end
