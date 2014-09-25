require 'res_helper'
require 'resque-retry'
class AaGrab
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  extend ResHelper
  @queue = :aa_queue
  @retry_limit = 5
  @retry_delay = 30

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	
	##AMERICAN AIRLINES
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com")
  	if aa_messages.count > 0
	  	#aa_messages = aa_messages.map {|message| message.body_parts.first.content}
	  	aa_messages.each do |message|
	  		email_message = message.body_parts.first.content
	  		trip = Trip.find_or_create_by_name_and_user_id(user_id: user.id, message_id: message.message_id)
			#trip info
			email_message.scan(/TICKET TOTAL (.*)/).each do |trip|
				fare = trip.first
			end
			email_message.scan(/DATE OF ISSUE - (.*)/).each do |trip|
				issue = trip.first
				issue_numbers = issue.scan(/\d/)
				@issue_year = "#{issue_numbers[2]}#{issue_numbers[3]}"
			end

			#departure info 1
			departure_array = Array.new
			departure_time_array = Array.new
			email_message.scan(/LV (.*)/).each do |departure|
		  		departure_data = departure.first.split
		  		word_count = departure_data.count
		  		if word_count > 7
		  			if word_count == 8
		  				departure_array << "#{departure_data[0]} #{departure_data[1]} #{departure_data[2]}"
		  				departure_time_array << "#{departure_data[3]} #{departure_data[4]}"
		  			else
		  				departure_array << "#{departure[0]} #{departure_data[1]} #{departure_data[2]} #{departure_data[3]}"
		  				departure_time_array << "#{departure_data[4]} #{departure_data[5]}"
		  			end
		  		else
		  			if word_count == 6
		  				departure_array << "#{departure_data[0]}"
						departure_time_array << "#{departure_data[1]} #{departure_data[2]}"
		  			else
						departure_array << "#{departure_data[0]} #{departure_data[1]}"
						departure_time_array << "#{departure_data[2]} #{departure_data[3]}"
					end
		  		end
			end

			#departure info 2
	  		departure_day_of_month_array = Array.new
	  		departure_month_array = Array.new
	  		departure_total = Array.new
	  		new_message = email_message.split("LV")
	  		new_message.pop
			new_message.each do |departure_split|
				departure_total << departure_split.split.last(3)
				departure_day_of_month_array << get_first_number(departure_split.split.last(3)[0])
				temp_num = get_first_number(departure_split.split.last(3)[0])
				departure_month_array << get_string_from_number_split(departure_split.split.last(3)[0], temp_num)
			end
			departure_day_of_month_array = departure_day_of_month_array.reject(&:empty?)

			#Arrival Data
			arrival_airport_array = Array.new
			arrival_time_array = Array.new
			seat_array = Array.new
			email_message.scan(/AR (.*)/).each do |arrival|
				arrival_data = arrival.first.split
				word_count = arrival_data.count
				if word_count > 5
					if word_count == 6
						arrival_airport_array << "#{arrival_data[0]} #{arrival_data[1]} #{arrival_data[2]}"
						arrival_time_array << "#{arrival_data[3]} #{arrival_data[4]}"
						seat_array << "#{arrival_data[5]}"
					else
						arrival_airport_array << "#{arrival_data[0]} #{arrival_data[1]} #{arrival_data[2]} #{arrival_data[3]}"
						arrival_time_array << "#{arrival_data[4]} #{arrival_data[5]}"
						seat_array << "#{arrival_data[6]}"
					end
				else
					if word_count == 4
						arrival_airport_array << "#{arrival_data[0]}"
						arrival_time_array << "#{arrival_data[1]} #{arrival_data[2]}"
						seat_array << "#{arrival_data[3]}"
					else
						arrival_airport_array << "#{arrival_data[0]} #{arrival_data[1]}"
						arrival_time_array << "#{arrival_data[2]} #{arrival_data[3]}"
						seat_array << "#{arrival_data[4]}"
					end
				end
			end
			flight_array = (0...departure_day_of_month_array.length).map{|i| 
		  		{
		  			departure_time: create_saveable_date(departure_day_of_month_array[i].to_s,departure_month_array[i],@issue_year, departure_time_array[i] ),
		  			departure_airport: departure_array[i],
		  			arrival_airport: arrival_airport_array[i],
		  			arrival_time: create_saveable_date(departure_day_of_month_array[i].to_s,departure_month_array[i],@issue_year, arrival_time_array[i] ),
		  			seat: seat_array[i]
		  		}
	  		}
	  		flight_array.each do |flight|
	  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 2, depart_airport: flight[:departure_airport], depart_time: flight[:departure_time], arrival_airport: flight[:arrival_airport], arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
	  		end
	  	end
	end
  end
end