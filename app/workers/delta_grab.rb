require 'res_helper'
require 'resque-retry'
class DeltaGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  @queue = :delta_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	airline_id = Airline.find_by_name("Delta Air Lines").id
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	##DELTA
	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com", limit: 500)
  	delta_messages.each do |message|
	  	if Trip.find_by_message_id(message.message_id).nil?
		  	year = message.received_at.strftime('%Y')
		  	dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body//pre/text()').map(&:to_s)
		  	
			#get overall data
		  	fare = matches[2].scan(/Fare: (.+)/).first.first.strip.split(/\s+/).first
		  	issue_data = matches.last.match(/Issue date:(.*)/).to_s
		  	issue_date = split_by_space(issue_data)[2]
		  	issue_year = issue_date.split(//).last(2).join("").to_i
		  	

			depart_city_array = Array.new
			depart_hour_array = Array.new
			d_matches = matches[0].scan(/\LV(.*)/).select{|t| t if t.first.length > 2}
			d_matches.each do |departure|			
				departure_data = departure.first.strip.split(/\s+/)
				if departure_data.count > 3
					departure_data.pop(2)
				else
					departure_data.pop
				end
				depart_hour_array << departure_data.pop
				depart_city_array << departure_data.join(" ")
			end
		  	
		  	#arrival information
		  	arrival_hour_array = Array.new
		  	arrival_city_array = Array.new
		  	a_matches = matches[0].scan(/AR (.*?)COACH/).select{|t| t if t.first.length > 2}
		  	a_matches.each do |lv|
		  		arrival_row = lv.first.split
		  		arrival_hour_array << arrival_row.pop
		  		arrival_city_array << arrival_row.join(" ")
		  	end
			
			depart_day_array = Array.new
		  	depart_month_array = Array.new
		  	de_matches = matches[0].scan(/(^.*?)LV/).select{|t| t if t.first.length > 2}
		  	de_matches.shift if de_matches.count > a_matches.count
		  	de_matches.each do |departures|
		  		depart_day_array << departures.first.strip.split(/\s+/)[1].match(/\d+/).to_s
		  		depart_month_array << month_to_number(departures.first.strip.split(/\s+/)[1].split(departures.first.strip.split(/\s+/)[1].match(/\d+/).to_s).last)
			end
			

		  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  	
		  	arrival_city_array.each_with_index do |x, i|
		  		depart_city = depart_city_array[i]
		  		arrival_city = arrival_city_array[i]
		  		
		  		day = depart_day_array[i]
		  		month = depart_month_array[i]
		  		
	  			arrival_hour = am_pm_split(arrival_hour_array[i])
	  			depart_hour = am_pm_split(depart_hour_array[i])

	  			arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
	  			depart_time = DateTime.new(year.to_i,month.to_i,day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

				begin
					depart_airport = Airport.find_by_city(depart_city.titleize).id
					deflightfix = false
				rescue Exception => e
					de = city_error_check(depart_city, 1, airline_id, message.message_id, trip.id)
					rollbar_error(message.message_id, depart_city, airline_id, user_id) if de.airport_id.blank?
					depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
					deflightfix = true if de.airport_id.blank? #set flag
				end

				begin
					arrival_airport = Airport.find_by_city(arrival_city.titleize).id
					aeflightfix = false
				rescue Exception => e
					ae = city_error_check(arrival_city, 2, airline_id, message.message_id, trip.id)
					rollbar_error(message.message_id, arrival_city, airline_id, user_id) if ae.airport_id.blank?
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
						f.seat_type = "Delta"
				end
		  			
		  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
		  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
			end
		end
	end
	delta_messages = account.messages.where(from: "DeltaAirLines@e.delta.com", limit: 5000)
  	no_subjects = ["It's Time To Check-In", "Your SkyMiles Account", "Your SkyMiles Password", "Reminder: Your January SkyMiles STATEMENT", "Reminder: Your February SkyMiles STATEMENT", "Reminder: Your March SkyMiles STATEMENT","Reminder: Your April SkyMiles STATEMENT", "Reminder: Your May SkyMiles STATEMENT", "Reminder: Your June SkyMiles STATEMENT", "Reminder: Your July SkyMiles STATEMENT", "Reminder: Your September SkyMiles STATEMENT", "Reminder: Your October SkyMiles STATEMENT", "Reminder: Your November SkyMiles STATEMENT", "Reminder: Your December SkyMiles STATEMENT", "Your January SkyMiles STATEMENT","Your February SkyMiles STATEMENT", "Your March SkyMiles STATEMENT", "Your April SkyMiles STATEMENT", "Your May SkyMiles STATEMENT", "Your June SkyMiles STATEMENT", "Your July SkyMiles STATEMENT", "Your August SkyMiles STATEMENT", "Your September SkyMiles STATEMENT", "Your October SkyMiles STATEMENT", "Your Novemeber SkyMiles STATEMENT", "Your December SkyMiles STATEMENT"]
  	good_messages = delta_messages.select{|m| m unless no_subjects.include?(m.subject)}
  	good_messages.each do |message|
	  	if Trip.find_by_message_id(message.message_id).nil?
		  	dom = Nokogiri::HTML(message.body_parts.first.content)
		  	year = message.received_at.strftime("%Y")
		  	flights = dom.xpath('/html/body/table/tr/td/table[3]/tr/td[2]/table[4]/tr/td[2]/table[6]/tr')
		  	if flights.count == 10 || flights.count == 5
		  		flight_array = dom.xpath('/html/body/table/tr/td/table[3]/tr/td[2]/table[4]/tr/td[2]/table[6]/tr').each_slice(5).to_a
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		flight_array.each_with_index do |f, i|
		  			x = i * 5
			  		flight_date = flights[x].xpath('td[3]').text().split[1]
			  		flight_day = flight_date.match(/\d+/).to_s
			  		flight_month = month_to_number(flight_date.split(flight_day)[1])
			  		flight_depart_time = am_pm_split(flights[x+2].xpath('td[3]').text().split[1])
			  		depart_city = flights[x+2].xpath('td[5]').text()
			  		flight_arrival_time = am_pm_split(flights[x+2].xpath('td[7]').text().split[1])
			  		arrival_city = flights[x+2].xpath('td[9]').text()
			  		
			  		depart_time = DateTime.new(year.to_i, flight_month.to_i, flight_day.to_i, flight_depart_time[:hour].to_i,flight_depart_time[:min].to_i, 0, 0)
			  		arrival_time = DateTime.new(year.to_i, flight_month.to_i, flight_day.to_i, flight_arrival_time[:hour].to_i,flight_arrival_time[:min].to_i, 0, 0)
					
					begin
		  				depart_airport = Airport.find_by_city(depart_city.titleize).id
		  				deflightfix = false
		  			rescue Exception => e
		  				de = city_error_check(depart_city, 1, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, depart_city, airline_id, user_id) if de.airport_id.blank?
		  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
		  				deflightfix = true if de.airport_id.blank? #set flag
			  		end
					
					begin
		  				arrival_airport = Airport.find_by_city(arrival_city.titleize).issue_date
		  				aeflightfix = false
		  			rescue Exception => e
		  				ae = city_error_check(arrival_city, 2, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, arrival_city, airline_id, user_id) if ae.airport_id.blank?
		  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
		  				aeflightfix = true if ae.airport_id.blank? #set flag
			  		end

				  	flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.depart_time = depart_time
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = arrival_time
		  				f.seat_type = "Delta"
					end
			  			
			  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix

			  	end


			else
				
			end
		end
	end
  end
end