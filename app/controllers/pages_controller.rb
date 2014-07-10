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
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com")
  	aa_messages = aa_messages.map {|message| message.body_parts.first.content}

  	
  	aa_messages.each do |message|
		#trip info
		message.scan(/TICKET TOTAL (.*)/).each do |trip|
			fare = trip.first
		end
		message.scan(/DATE OF ISSUE - (.*)/).each do |trip|
			issue = trip.first
			issue_numbers = issue.scan(/\d/)
			@issue_year = "#{issue_numbers[2]}#{issue_numbers[3]}"
		end

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
  		new_message = message.split("LV")
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
		message.scan(/AR (.*)/).each do |arrival|
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
  			Flight.create(trip_id: 3, airline_id: 2, depart_airport: flight[:departure_airport], depart_time: flight[:departure_time], arrival_airport: flight[:arrival_airport], arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
  		end
  	end

  end
  def usairways
  	#auth into contextio
  	contextio = ContextIO.new('p3o3c7vm', '8kYkj7Qv9xKeVitj')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	#get messages from delta and pick the html
  	usa_messages = account.messages.where(from: "reservations@email-usairways.com")
  	usa_messages = usa_messages.map {|message| message.body_parts.first.content}
  	usa_messages.each do |message|
  		#:bold;color:#277DB2;">(.*?)<\/span>
  		airport_array = message.scan(/:bold;color:#277DB2;">(.*?)<\/span>/)
	  	stripped = ActionView::Base.full_sanitizer.sanitize(message)
	  	stripped = stripped.gsub("\n","")
	  	stripped = stripped.gsub("\r","")
	  	stripped = stripped.gsub("\t","")
	  	#stripped = stripped.gsub("&nbsp;","")
	  	raise "#{stripped}"

	  	fare = stripped.scan(/Subtotal(.*?)Number/).first.first
	  	departure_array =  stripped.scan(/DEPART(.*?)AIRCRAFT/)
	  	
	  	weird_date_arrays = stripped.scan(/\bto\b(.*?)FLIGHT#/)
	  	date_arrays = weird_date_arrays.map{|full_date| full_date.first.split.last(3) }
	  	
	  	raise "#{date_arrays}"
	  	
	  	#binding.pry
	  

	  	
	  	#raise "#{stripped.scan(/ARRIVE &nbsp; &nbsp;(.*?)&nbsp;/)}"




  	end
  end
  def jetblue
  	#auth into contextio
  	contextio = ContextIO.new('p3o3c7vm', '8kYkj7Qv9xKeVitj')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	#get messages from delta and pick the html
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip")
  	jb_messages = jb_messages.map {|message| message.body_parts.first.content}
  	jb_messages.each do |message|
  		@message = message
  		dom = Nokogiri::HTML(message)
	  	matches = dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').map(&:to_s)
	  	matches.pop(5)
	  	matches.shift
	  	matches = matches.select.each_with_index { |str, i| i.even? }

	  	matches.each do |match|
	  		both_airports = match.scan(/<strong>(.*?)<\/strong>/)
	  		@both_airports = both_airports
	  		match_strip = ActionView::Base.full_sanitizer.sanitize(match)
	  		match_split = match_strip.split

	  		if match_split[3] == "-"
		  		departure_month = match_split[1]
		  		departure_date = match_split[2]
		  		departure_time = match_split[7]
		  		
		  		arrival_month = match_split[5]
		  		arrival_date = match_split[6]
		  		arrival_time = match_split[8]
				departure_time = create_saveable_date(departure_date, departure_month, 2012, departure_time)
		  		arrival_time = create_saveable_date(arrival_date, arrival_month, 2012, arrival_time)
	  		elsif match_split[1].to_i !=0
	  			if match_split[2] == "-"
			  		departure_month = match_split[0]
			  		departure_date = match_split[1]
			  		departure_time = match_split[6]
			  		
			  		arrival_month = match_split[4]
			  		arrival_date = match_split[5]
			  		arrival_time = match_split[7]
					departure_time = create_saveable_date(departure_date, departure_month, 2012, departure_time)
			  		arrival_time = create_saveable_date(arrival_date, arrival_month, 2012, arrival_time)

	  			else 
		  			departure_month = match_split[0]
			  		departure_date = match_split[1]
			  		departure_time = match_split[2]
			  		arrival_time = match_split[3]

					departure_time = create_saveable_date(departure_date, departure_month, 2011, departure_time)
			  		arrival_time = create_saveable_date(departure_date, departure_month, 2011, arrival_time)

			  	end
	  		else
		  		date_shift = match_split.shift(5)
		  		flight_date = date_shift.shift(3)
		  		both_times = date_shift.pop(2)
		  		departure_time = create_saveable_date(flight_date[2], flight_date[1], 2012, both_times.first)
		  		arrival_time = create_saveable_date(flight_date[2], flight_date[1], 2012, both_times[1])
		  	end

	  		Flight.create(trip_id: 6, airline_id: 1, depart_airport: both_airports.first.first, depart_time: departure_time, arrival_airport: both_airports[1].first, arrival_time: arrival_time, seat_type: "COACH" )
	  		
	  	end
  	end
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
  	if month.length < 4
  		num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
  	else
  		num_month = month
  	end
  	string_date = "#{day}/#{num_month}/#{year} #{hour}"
  	real_date = Chronic.parse(string_date)
  	return real_date
  end
end
