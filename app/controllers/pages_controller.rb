class PagesController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'chronic'

  def home
  end

  def about
  	#auth into contextio
  	contextio = ContextIO.new('p3o3c7vm', '8kYkj7Qv9xKeVitj')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	#get messages from delta and pick the html
  	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com")
  	delta_messages = delta_messages.map {|message| message.body_parts.first.content}

  	delta_messages.each do |message_string|
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
	  		Flight.create(trip_id: 14, airline_id: 12, depart_airport: flight[:departure_airport], depart_time: flight[:departure_time], arrival_airport: flight[:arrival_airport], arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
	  	end
	end
  end

  def contact
  	#auth into contextio
  	contextio = ContextIO.new('p3o3c7vm', '8kYkj7Qv9xKeVitj')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	#get messages from delta and pick the html
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com", subject: "E-Ticket Confirmation")
  	
  	aa_messages = aa_messages.map {|message| message.body_parts.first.content}
  	aa_messages.each do |message|
			
			#departure info 1
			departure_array = Array.new
  			departure_time_array = Array.new
  			message.scan(/LV (.*)/).each do |departure|
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
					departure_array << "#{departure_data[0]} #{departure_data[1]}"
					departure_time_array << "#{departure_data[2]} #{departure_data[3]}"
		  		end
  			end

  			#departure info 2
	  		departure_day_of_month_array = Array.new
	  		departure_month_array = Array.new
	  		departure_total = Array.new
	  		#raise "#{message.split("LV").first.split.last(3)}"
	  		#raise "#{message.split("LV")}"
	  		new_message = message.split("LV")
	  		new_message.pop
  			new_message.each do |departure_split|
  				departure_total << departure_split.split.last(3)
  				departure_day_of_month_array << get_first_number(departure_split.split.last(3)[0])
  				temp_num = get_first_number(departure_split.split.last(3)[0])
  				departure_month_array << get_string_from_number_split(departure_split.split.last(3)[0], temp_num)
  			end
  			departure_day_of_month_array = departure_day_of_month_array.reject(&:empty?)
  			raise "#{departure_month_array}"

  	end
  	#Get the First Flight LV and AR string.split[0..15]

  end

  private

  def get_first_number(full_string)
  	return full_string.match(/\d+/).to_s
  end

  def get_string_from_number_split(full_string, number)
  	return full_string.split(number)[1]
  end

  def split_by_space(full_string)
  	return full_string.strip.split(/\s+/)
  end

  def create_saveable_date(day, month, year, hour)
  	num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
  	string_date = "#{day}/#{num_month}/#{year} #{hour}"
  	real_date = Chronic.parse(string_date)
  	return real_date
  end
end
