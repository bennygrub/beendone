class Flight < ActiveRecord::Base
	belongs_to :trip
	default_scope  { order(:depart_time => :asc) }
end
