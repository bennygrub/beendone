require 'res_helper'
require 'resque-retry'
class UnitedGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  
  @queue = :united_queue
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

  	airline_id = Airline.find_by_name("United Airlines").id

	email_change_date = Date.new(2011,1,1).to_time.to_i #date that email changed
  	u_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', limit: 500)
	u_messages.each do |message|
		if Trip.find_by_message_id(message.message_id).nil?
			dom = Nokogiri::HTML(message.body_parts.first.content)
			matches = dom.xpath('//*[@id="i"]/table[@style="width:511px;font:11px/15px Arial, sans-serif;"]').map(&:to_s)
			if matches.count > 0
				trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
				matches.each do |flight|
						flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
				  		date_split = flight_data.scan(/<span>(.*?)<\/span>/).first.first.split
				  		date_split = date_split.first.split(",")
				  		year = date_split[2]
				  		day = get_first_number(date_split[1])
				  		month = date_split[1].split("#{day}").first
				  		depart_split = flight_data.scan(/Depart: (.*?)<br>/).first.first.split
				  		depart_hour_min = am_pm_split(depart_split[1] + depart_split[2])
				  		depart_time = flight_date_time(day, month, year, depart_hour_min[:hour], depart_hour_min[:min])
				  		arrive_split = flight_data.scan(/Arrive: (.*?)<\/td>/).first.first.split
				  		arrive_hour_min = am_pm_split(arrive_split[1]+arrive_split[2])
				  		arrival_time = flight_date_time(day, month, year, arrive_hour_min[:hour], arrive_hour_min[:min])
				  		
			  			begin
			  				depart_airport = Airport.find_by_faa(depart_split[0]).id
			  				deflightfix = false
			  			rescue Exception => e
			  				de = city_error_check(depart_split[0], 1, airline_id, message.message_id, trip.id)
			  				rollbar_error(message.message_id, depart_split[0], airline_id, user_id) if de.airport_id.blank?
			  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id.id#Random airport
			  				deflightfix = true if de.airport_id.blank? #set flag
				  		end

			  			begin
			  				arrival_airport = Airport.find_by_faa(arrive_split[0]).id
			  				aeflightfix = false
			  			rescue Exception => e
			  				ae = city_error_check(arrive_split[0], 1, airline_id, message.message_id, trip.id)
			  				rollbar_error(message.message_id, arrive_split[0], airline_id, user_id) if ae.airport_id.blank?
			  				arrival_airport = ae.airport_id.blank? ? 1 : ae.airport_id.id#Random airport
			  				aeflightfix = true if ae.airport_id.blank? #set flag
				  		end


				  		#seat_split = flight_data.scan(/Booking class: (.*?)<a/).first.first
				  		#seat_type = seat_split.scan(/<br>(.*?)<br>/).first.first
				  		seat_type = "Economy"
				  		flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
			  				f.trip_id = trip.id
			  				f.airline_id = airline_id
			  				f.depart_airport = depart_airport
			  				f.depart_time = depart_time
			  				f.arrival_airport = arrival_airport
			  				f.arrival_time = arrival_time
			  				f.seat_type = seat_type
						end
			  			FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  			FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
				end
			else
  				##OLD UNITED
		  		matches = dom.xpath('//*[@id="flightTable"]/tr[@style="vertical-align: top;"]').map(&:to_s)
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		matches.each do |flight|
		  			if flight.scan(/<p>(.*?)<\/p>/).count < 1 
						flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
				  		seat_type = flight_data.scan(/<td style="padding-bottom:20px;">(.*?)<\/td>/).first.first
			  			flight_data = flight_data.scan(/<td>(.*?)<\/td>/)  			
			  			departure_data = flight_data.first.first.scan(/\>(.*?)\</)

			  			d_airport = departure_data[0].first
			  			depart_hour = departure_data[1].first
			  			depart_time_data = departure_data[3].first.split
			  			depart_month = depart_time_data[1]
			  			depart_day = depart_time_data[2]
			  			depart_year = depart_time_data[3]
			  			depart_time = create_saveable_date(depart_day, depart_month, depart_year, depart_hour)

			  			arrival_data = flight_data[1].first.scan(/\>(.*?)\</)
			  			a_airport = arrival_data[0].first
			  			arrival_hour = arrival_data[1].first
			  			arrival_time_data = arrival_data[3].first.split
			  			arrival_month = arrival_time_data[1]
			  			arrival_day = arrival_time_data[2]
			  			arrival_year = arrival_time_data[3]
			  			arrival_time = create_saveable_date(arrival_day, arrival_month, arrival_year, arrival_hour)

						begin
			  				depart_airport = Airport.find_by_faa(d_airport).id
			  				deflightfix = false
			  			rescue Exception => e
			  				de = city_error_check(d_airport, 1, airline_id, message.message_id, trip.id)
			  				rollbar_error(message.message_id, d_airport, airline_id, user_id) if de.airport_id.blank?
			  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id.id#Random airport
			  				deflightfix = true if de.airport_id.blank? #set flag
				  		end

			  			begin
			  				arrival_airport = Airport.find_by_faa(a_airport).id
			  				aeflightfix = false
			  			rescue Exception => e
			  				ae = city_error_check(a_airport, 1, airline_id, message.message_id, trip.id)
			  				rollbar_error(message.message_id, a_airport, airline_id, user_id) if ae.airport_id.blank?
			  				arrival_airport = ae.airport_id.blank? ? 1 : ae.airport_id.id#Random airport
			  				aeflightfix = true if de.airport_id.blank? #set flag
				  		end

			  			flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
			  				f.trip_id = trip.id
			  				f.airline_id = airline_id
			  				f.depart_airport = depart_airport
			  				f.depart_time = depart_time
			  				f.arrival_airport = arrival_airport
			  				f.arrival_time = arrival_time
			  				f.seat_type = seat_type
						end
			  			
			  			FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  			FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
		  			end
		  		end
			end
		end
	end
  end
end