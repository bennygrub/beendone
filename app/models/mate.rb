class Mate < ActiveRecord::Base
	belongs_to :user
	belongs_to :trip
	attr_accessor :email_user, :user_id
	after_create :invite_user
	validates_presence_of :name, :email

	def invite_user
		UserMailer.invite(user_id, self.email, self.name, self.trip_id) if self.email_user == '1'
	end
end
