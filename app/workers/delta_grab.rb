require 'res_helper'
require 'resque-retry'
class DeltaGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  @queue = :delta_queue
  @retry_limit = 5
  @retry_delay = 30

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	##DELTA
	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com")
  	if delta_messages.count > 0
	  	delta_messages = delta_messages.map {|message| message.body_parts.first.content}

	  	delta_messages.each do |message_string|
	  		trip = Trip.create(user_id: user.id)
		  	dom = Nokogiri::HTML(message_string)
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
		  	matches[0].scan(/(^.*?)LV/).each do |departures|
		  		departure_date_data = departures.to_s.strip.split(/\s+/)
		  		
			  	#departure information
			  	#departure_day_of_week = departure_date_data[0]
			  	departure_day_of_month_array << departure_date_data[1].match(/\d+/)
			  	departure_month_array << departure_date_data[1].split("#{departure_date_data[1].match(/\d+/)}")[1]
			  	#departure_time_data = matches[0].match(/\LV(.*)/).to_s.strip.split(/\s+/)
			  	#departure_array << departure_time_data[1]
			  	departure_day_array << departure_date_data.second
			  	#departure_array << departure_time_data[2]
			  	#departure_hour = departure_time_data[2].match(/\d+/)
			  	#departure_hour_seg = departure_time_data[2].split("#{departure_hour}")[1]
			end

			#departure_time_data = matches[0].match(/\LV(.*)/).to_s.strip.split(/\s+/)
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
		  		else
		  			depart_airport = Airport.find_by_city(flight[:departure_airport].titleize).id
		  		end
		  		if flight[:arrival_airport] == "NYC-LAGUARDIA" || flight[:arrival_airport] == "NYC-KENNEDY"
		  			arrival_nyc = flight[:arrival_airport].split("-").second
		  			arrival_code = arrival_nyc == "KENNEDY" ? "JFK" : "LGA"
		  			arrival_airport = Airport.find_by_faa(arrival_code).id 
		  		else
		  			arrival_airport = Airport.find_by_city(flight[:arrival_airport].titleize).id
		  		end

		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 12, depart_airport: depart_airport, depart_time: flight[:departure_time], arrival_airport: arrival_airport, arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
		  	end
		end
	end
  end
end