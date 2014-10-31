require 'res_helper'
require 'resque-retry'
class HotwireGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  
  @queue = :hotwire_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
  	if Rails.env.production?
  		contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	else
  		contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	end
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
  	airline_id = Airline.find_by_name("Hotwire").id

  	hw_messages = account.messages.where(from: "support@hotwire.com", subject: "/Hotwire Flight Purchase Confirmation/")
  	hw_messages.each do |message|
  		email = message.body_parts.first.content.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '')
  		depart_data = email.scan(/Departs:(.*?)Arrives:/)
  		arrival_data = email.scan(/Arrives:(.*?)Duration:/)
  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "Hotwire")
  		depart_data.each_with_index do |x, i|
  			depart = depart_data[i].first
  			depart_airport = Airport.find_by_faa(depart.scan(/\((.*?)\)/).first.first).id
  			depart_hour = am_pm_split(depart.scan(/at (.+)/).first.first)
  			depart_month_day_year = depart.scan(/\)(.*?) at/).first.first.split(",")
  			depart_year = depart_month_day_year[2]
  			depart_month = month_to_number(depart_month_day_year[1].split[0])
  			depart_day = depart_month_day_year[1].split[1].to_i

  			depart_time = DateTime.new(depart_year.to_i, depart_month.to_i, depart_day.to_i, depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

			arrival = arrival_data[i].first
  			arrival_airport = Airport.find_by_faa(arrival.scan(/\((.*?)\)/).first.first).id
  			arrival_hour = am_pm_split(arrival.scan(/\) (.*?) on/).first.first)
  			arrival_month_day_year = arrival.scan(/on (.+)/).first.first.split(",")
  			arrival_year = arrival_month_day_year[2]
  			arrival_month = month_to_number(arrival_month_day_year[1].split[0])
  			arrival_day = arrival_month_day_year[1].split[1].to_i

  			arrival_time = DateTime.new(arrival_year.to_i, arrival_month.to_i, arrival_day.to_i, arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)

            flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
              f.trip_id = trip.id
              f.airline_id = airline_id
              f.depart_airport = depart_airport
              f.depart_time = depart_time
              f.arrival_airport = arrival_airport
              f.arrival_time = arrival_time
              f.seat_type = "Hotwire"
            end

  		end
  	end
	#completed("Finished!")
  end
end