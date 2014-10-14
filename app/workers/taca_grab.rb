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
  	if Rails.env.production?
  		contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	else
  		contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	end
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
  	airline_id = Airline.find_by_name("TACA").id

  	taca_messages = account.messages.where(from: "edesk@taca.com", subject: "/TACA.COM/")
  	if taca_messages.count > 0
	  	taca_messages.each do |message|
	  		email = message.body_parts.first.content.gsub("\r","").gsub("\n","")
	  		airfare = email.scan(/USD (.*?)<BR>/)
	  		depart_times = email.scan(/Depart:(.*?)To:/)
	  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
	  		depart_times.each_with_index do |value, index|
	  			depart_time = am_pm_split(email.scan(/Depart:(.*?)To:/)[index].first.gsub(" ",""))
	  			depart_airport = Airline.find_by_faa(email.scan(/From:(.*?)Depart:/)[index].first.scan(/\((.*?)\)/).first.first)
	  			arrival_airport = Airline.find_by_faa(email.scan(/To:(.*?)Arrive:/)[index].first.scan(/\((.*?)\)/).first.first).id
	  			arrival_time = am_pm_split(email.scan(/Arrive:(.*?)Flight:/)[index].first.gsub(" ", ""))
	  			day_month_year = email.scan(/Date:(.*?)From:/)[index].first.split

	  			depart_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,depart_time[:hour].to_i,depart_time[:min].to_i, 0, 0)
	  			arrival_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,arrival_time[:hour].to_i,arrival_time[:min].to_i, 0, 0)
	            
	            flight = Flight.where(trip_id: trip.id, depart_time: depart_time.to_time).first_or_create do |f|
	              f.trip_id = trip.id
	              f.airline_id = airline_id
	              f.depart_airport = depart_airport
	              f.arrival_airport = arrival_airport
	              f.arrival_time = arrival_time
	              f.seat_type = "Taca"
	            end
	  		end
	  	end
	end 
  end
end