class Mate < ActiveRecord::Base
	belongs_to :user
	belongs_to :trip
	attr_accessor :email_user
	after_create :invite_user


	def invite_user
		#
	end
end
