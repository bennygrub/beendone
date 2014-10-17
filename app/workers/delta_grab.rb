require 'res_helper'
require 'resque-retry'
class DeltaGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  @queue = :delta_queue
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
  	airline_id = Airline.find_by_name("Delta Air Lines").id
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	##DELTA
	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com")
  	delta_messages.each do |message|
	  	if Trip.find_by_message_id(message.message_id).nil?
		  	dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body//pre/text()').map(&:to_s)
		  	
			#get overall data
		  	fare = matches[2].scan(/Fare: (.+)/).first.first.strip.split(/\s+/).first
		  	issue_data = matches.last.match(/Issue date:(.*)/).to_s
		  	issue_date = split_by_space(issue_data)[2]
		  	issue_year = issue_date.split(//).last(2).join("").to_i
		  	
		  	#departure data 1
		  	departure_day_array = Array.new
		  	departure_day_of_month_array = Array.new
		  	departure_month_array = Array.new
		  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  	matches[0].scan(/(^.*?)LV/).each do |departures|
		  		departure_date_data = departures.to_s.strip.split(/\s+/)
		  		
			  	#departure information
			  	departure_day_of_month_array << departure_date_data[1].match(/\d+/)
			  	departure_month_array << departure_date_data[1].split("#{departure_date_data[1].match(/\d+/)}")[1]
			  	departure_day_array << departure_date_data.second
			end
			departure_airport_array = Array.new
			departure_time_array = Array.new
			matches[0].scan(/\LV(.*)/).each do |departure|			
				departure_data = departure.to_s.strip.split(/\s+/)	
				word_count = departure_data.count
				if word_count > 5
					if word_count == 6
						departure_airport_array << "#{departure_data[1]} #{departure_data[2]}" 
						departure_time_array << departure_data[3]
					else
						departure_airport_array << "#{departure_data[1]} #{departure_data[2]} #{departure_data[3]}"
						departure_time_array << departure_data[4]
					end
				else
					departure_airport_array << departure_data[1]
					departure_time_array << departure_data[2]
				end			
			end
		  	
		  	#arrival information
		  	arrival_array = Array.new
		  	arrival_time_array = Array.new
		  	seat_array = Array.new
		  	matches[0].scan(/AR (.*)/).map{ |arrival|
		  		arrival_data = arrival.first.split
		  		word_count = arrival_data.count
		  		if word_count > 3
		  			if word_count == 4
		  				arrival_array << "#{arrival_data[0]} #{arrival_data[1]}"
		  				arrival_time_array << arrival_data[2]
		  				seat_array << arrival_data[3]
		  			else
		  				arrival_array << "#{arrival_data[0]} #{arrival_data[1]} #{arrival_data[2]}"
		  				arrival_time_array << arrival_data[3]
		  				seat_array << arrival_data[4]
		  			end
		  		else
					arrival_array << arrival_data[0]
					arrival_time_array << arrival_data[1] 
					seat_array << arrival_data[2]
		  		end
		  	}
		  	flight_array = (0...departure_day_array.length).map{|i| 
		  		{
		  			departure_time: create_saveable_date(departure_day_of_month_array[i].to_s,departure_month_array[i],issue_year, departure_time_array[i] ),
		  			departure_airport: departure_airport_array[i],
		  			arrival_airport: arrival_array[i],
		  			arrival_time: create_saveable_date(departure_day_of_month_array[i].to_s,departure_month_array[i],issue_year, arrival_time_array[i] ),
		  			seat: seat_array[i]
		  		}
		  	}

		  	flight_array.each do |flight|
		  		
		  		if flight[:departure_airport] == "NYC-LAGUARDIA" || flight[:departure_airport] == "NYC-KENNEDY"
		  			depart_nyc = flight[:departure_airport].split("-").second
		  			depart_code = depart_nyc == "KENNEDY" ? "JFK" : "LGA"
		  			depart_airport = Airport.find_by_faa(depart_code).id 
		  		elsif flight[:departure_airport] == "CHICAGO-OHARE"
					depart_airport = Airport.find_by_faa("ORD").id
		  		elsif flight[:departure_airport] == "ST LOUIS" || flight[:departure_airport] == "ST"
					depart_airport = Airport.find_by_faa("STL").id
		  		else
		  			depart_city = flight[:departure_airport]
	  				begin
		  				depart_airport = Airport.find_by_city(depart_city.titleize).id
		  				deflightfix = false
		  			rescue Exception => e
		  				de = city_error_check(depart_city, 1, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, depart_city, airline_id, user_id) if de.airport_id.blank?
		  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
		  				deflightfix = true if de.airport_id.blank? #set flag
			  		end
		  		end
		  		if flight[:arrival_airport] == "NYC-LAGUARDIA" || flight[:arrival_airport] == "NYC-KENNEDY"
		  			arrival_nyc = flight[:arrival_airport].split("-").second
		  			arrival_code = arrival_nyc == "KENNEDY" ? "JFK" : "LGA"
		  			arrival_airport = Airport.find_by_faa(arrival_code).id 
		  		elsif flight[:arrival_airport] == "CHICAGO-OHARE"
		  			arrival_airport = Airport.find_by_faa("ORD").id
		  		elsif flight[:arrival_airport] == "ST LOUIS" || flight[:arrival_airport] == "ST"
		  			arrival_airport = Airport.find_by_faa("STL").id
		  		else	
	  				arrival_city = flight[:arrival_airport]
	  				begin
		  				arrival_airport = Airport.find_by_city(arrival_city.titleize).id
		  				aeflightfix = false
		  			rescue Exception => e
		  				ae = city_error_check(arrival_city, 2, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, arrival_city, airline_id, user_id) if ae.airport_id.blank?
		  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
		  				aeflightfix = true if ae.airport_id.blank? #set flag
			  		end
		  		end

				flight = Flight.where(depart_time: flight[:departure_time]).first_or_create do |f|
	  				f.trip_id = trip.id
	  				f.airline_id = airline_id
	  				f.depart_airport = depart_airport
	  				f.depart_time = flight[:departure_time]
	  				f.arrival_airport = arrival_airport
	  				f.arrival_time = flight[:arrival_time]
	  				f.seat_type = "Delta"
				end
		  			
		  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
		  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix

		  	end
		end
	end
  end
end