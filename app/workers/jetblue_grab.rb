require 'res_helper'
require 'resque-retry'
class JetblueGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  @queue = :jetblue_queue
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
	airline_id = Airline.find_by_name("JetBlue").id
	##JETBLUE NEW
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip")
  	jb_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		year = message.received_at.strftime("%Y")
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		number_of_flights = (dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').count-5)/2
	  		flight_loop = (1..number_of_flights).to_a
	  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
	  		flight_loop.each_with_index do |flight, index|
	  			flight_index = (index + 1)*2
	  			flight_data = dom.xpath("//*[@id='ticket']/div/table/tr/td/table[4]/tr[#{flight_index}]/td")
	  			day_count = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.count
	  			day = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-1].to_i
	  			month = month_to_number(flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-2])
	  			d_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.first)
	  			a_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.last)

		  		message_year_check(month, year)
		  		depart_time = DateTime.new(year.to_i, month.to_i, day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)
	  			arrival_time = DateTime.new(year.to_i, month.to_i, day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

		  		airport_cities = flight_data[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<strong>(.*?)<\/strong>/)
		  		d_city = airport_cities.first.first.split(",").first.titleize
		  		a_city = airport_cities.last.first.split(",").first.titleize
		  		
				begin
	  				depart_airport = Airport.find_by_city(d_city).id
	  				deflightfix = false
	  			rescue Exception => e
	  				de = city_error_check(d_city, 1, airline_id, message.message_id, trip.id)
	  				rollbar_error(message.message_id, d_city, airline_id, user_id) if de.airport_id.blank?
	  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
	  				deflightfix = true if de.airport_id.blank? #set flag
		  		end

				begin
	  				arrival_airport = Airport.find_by_city(a_city).id
	  				aeflightfix = false
	  			rescue Exception => e
	  				ae = city_error_check(a_city, 2, airline_id, message.message_id, trip.id)
	  				rollbar_error(message.message_id, a_city, airline_id, user_id) if ae.airport_id.blank?
	  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
	  				aeflightfix = true if ae.airport_id.blank? #set flag
		  		end

	  			
				flight = Flight.where(depart_time: depart_time).first_or_create do |f|
	  				f.trip_id = trip.id
	  				f.airline_id = airline_id
	  				f.depart_airport = depart_airport
	  				f.depart_time = depart_time
	  				f.arrival_airport = arrival_airport
	  				f.arrival_time = arrival_time
	  				f.seat_type = "Jetblue"
				end
		  			
		  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
		  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
	  		end
	  	end
  	end

  	#JetBlue OLDER
  	jb_messages_old = account.messages.where(from: "mail@jetblueconnect.com", subject: "Your JetBlue E-tinerary")
  	jb_messages_old.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body/div/table/tr[11]/td/table/tr').map(&:to_s)
		  	matches.shift(2)
		  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  	matches.each do |match|
		  		flight_array = match.scan(/>(.*?)</)
		  		date = flight_array[0].first
		  		departure_data = flight_array[2].first	  		
		  		depart_time = departure_data.split.pop
		  		depart_city = flight_array[2].first.split(",").first
		  		if depart_city == "New York"
		  			depart_code = flight_array[2].first.split(",").second.split(" ").first
		  			depart_airport = Airport.find_by_faa(depart_code).id
		  		else
					begin
		  				depart_airport = Airport.find_by_city(depart_city).id
		  				deflightfix = false
		  			rescue Exception => e
		  				de = city_error_check(depart_city, 1, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, depart_city, airline_id, user_id) if de.airport_id.blank?
		  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
		  				deflightfix = true if de.airport_id.blank? #set flag
			  		end
		  		end
		  		arrival_city = flight_array[3].first.split(",").first
		  		if arrival_city == "New York"
		  			arrival_code = flight_array[3].first.split(",").second.split(" ").first
		  			arrival_airport = Airport.find_by_faa(arrival_code).id
		  		else
					begin
		  				arrival_airport = Airport.find_by_city(arrival_city).id
		  				aeflightfix = false
		  			rescue Exception => e
		  				ae = city_error_check(arrival_city, 2, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, arrival_city, airline_id, user_id) if ae.airport_id.blank?
		  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
		  				aeflightfix = true if ae.airport_id.blank? #set flag
			  		end
		  		end

		  		arrival_data = flight_array[3].first
		  		arrival_time = arrival_data.split.pop
		  		arrival_time = old_jb_time(date,arrival_time)
		  		depart_time = old_jb_time(date,depart_time)
			  	

			  	flight = Flight.where(depart_time: depart_time).first_or_create do |f|
	  				f.trip_id = trip.id
	  				f.airline_id = airline_id
	  				f.depart_airport = depart_airport
	  				f.depart_time = depart_time
	  				f.arrival_airport = arrival_airport
	  				f.arrival_time = arrival_time
	  				f.seat_type = "Jetblue"
				end
	  			
		  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
		  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
		  	end
		end
	end
  end
end