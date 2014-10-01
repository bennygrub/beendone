require 'res_helper'
require 'resque-retry'
class TacaGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :taca_queue
  @retry_limit = 5
  @retry_delay = 30

  def self.perform(job_id, user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first


  	taca_messages = account.messages.where(from: "edesk@taca.com", subject: "/TACA.COM/")
  	if taca_messages.count > 0
	  	taca_messages.each do |message|
	  		#trip = Trip.create(user_id: current_user.id, name: "taca", message_id: message.message_id)
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "Taca")
	  		
	  		email = message.body_parts.first.content.gsub("\r","").gsub("\n","")
	  		
	  		airfare = email.scan(/USD (.*?)<BR>/)
	  		
	  		depart_times = email.scan(/Depart:(.*?)To:/)
	  		
	  		depart_times.each_with_index do |value, index|
	  			#binding.pry
	  			depart_time = am_pm_split(email.scan(/Depart:(.*?)To:/)[index].first.gsub(" ",""))
	  			depart_airport = email.scan(/From:(.*?)Depart:/)[index].first.scan(/\((.*?)\)/).first.first
	  			arrival_airport = email.scan(/To:(.*?)Arrive:/)[index].first.scan(/\((.*?)\)/).first.first
	  			arrival_time = am_pm_split(email.scan(/Arrive:(.*?)Flight:/)[index].first.gsub(" ", ""))
	  			day_month_year = email.scan(/Date:(.*?)From:/)[index].first.split

	  			d_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,depart_time[:hour].to_i,depart_time[:min].to_i, 0, 0)
	  			a_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,arrival_time[:hour].to_i,arrival_time[:min].to_i, 0, 0)

	  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 191, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: d_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: a_time, seat_type: "taca" )
	  		end
	  	end
	end 
  end
end