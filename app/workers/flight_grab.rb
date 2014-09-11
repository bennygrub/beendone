require 'res_helper'
class FlightGrab
  extend ResHelper
  @queue = :flights_queue

  def self.perform(flight_id)
	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	
	#VIRGIN
  	#get messages from Virgin and pick the html
  	va_messages = account.messages.where(from: "virginamerica@elevate.virginamerica.com", subject: "/Virgin America Reservation/")
  	if va_messages.count > 0
	  	va_messages = va_messages.map {|message| message.body_parts.first.content}
	  	va_messages.each do |message|
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('/html/body/table/tr[14]/td/table/tr[2]/td/table/tr').map(&:to_s)
		  	matches.shift
		  	matches.each do |match|
		  		new_match = match.gsub("<br>"," ")
		  		match_strip = ActionView::Base.full_sanitizer.sanitize(new_match)
		  		flight_array = match_strip.gsub(",", "")
		  		match_split = flight_array.split
		  		date = match_split[0]
		  		match_split.shift(3)
		  		match_join = match_split.join(" ")
		  		both_times = match_join.scan(/\)(.*?)M/)
		  		both_airports = match_join.scan(/\((.*?)\)/)
		  		d_time = Time.parse("#{date} #{both_times[0].first}")
		  		a_time = Time.parse("#{date} #{both_times[1].first}")
		  		Flight.find_or_create_by_depart_time(trip_id: 24, airline_id: 23, depart_airport: both_airports[0].first, depart_time: d_time, arrival_airport: both_airports[1].first, arrival_time: a_time, seat_type: "COACH" )
		  	end	
	  	end
	end

  	##JETBLUE NEW
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip")
  	if jb_messages.count > 0
	  	jb_messages = jb_messages.map {|message| message.body_parts.first.content}
	  	jb_messages.each do |message|
	  		@message = message
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').map(&:to_s)
		  	matches.pop(5)
		  	matches.shift
		  	matches = matches.select.each_with_index { |str, i| i.even? }
		  	#match = matches[1]
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

		  		Flight.find_or_create_by_depart_time(trip_id: 6, airline_id: 1, depart_airport: both_airports.first.first, depart_time: departure_time, arrival_airport: both_airports[1].first, arrival_time: arrival_time, seat_type: "COACH" )
		  	end
	  	end
	end




  	#JetBlue
  	jb_messages_old = account.messages.where(from: "mail@jetblueconnect.com", subject: "Your JetBlue E-tinerary")
  	if jb_messages_old.count > 0
	  	jb_messages_old = jb_messages_old.map {|message| message.body_parts.first.content}
	  	jb_messages_old.each do |message|
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('/html/body/div/table/tr[11]/td/table/tr').map(&:to_s)
		  	matches.shift(2)
		  	matches.each do |match|
		  		flight_array = match.scan(/>(.*?)</)
		  		date = flight_array[0].first
		  		departure_data = flight_array[2].first	  		
		  		depart_time = departure_data.split.pop
		  		d_split = departure_data.split
		  		d_split.pop
		  		depart_airport = d_split.join(" ")
		  		arrival_data = flight_array[3].first
		  		arrival_time = arrival_data.split.pop
		  		a_split = arrival_data.split
		  		a_split.pop
		  		arrival_airport = a_split.join(" ")
		  		arrival_time = old_jb_time(date,arrival_time)
		  		depart_time = old_jb_time(date,depart_time)
		  		Flight.find_or_create_by_depart_time(trip_id: 6, airline_id: 1, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "COACH" )
		  	end
		end
	end

	#CHEAPO AIR
  	c_messages = account.messages.where(from: "cheapoair@cheapoair.com", subject: '/AIR TICKET/i')
	if c_messages.count > 0
		c_messages = c_messages.map {|message| message.body_parts.first.content}
		
		c_messages.each do |message|
			dom = Nokogiri::HTML(message)
			year_data = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr[1]').map(&:to_s).first
			year_data = year_data.gsub("\t","")
	  		year_data = year_data.gsub("\n","")
	  		year_data = year_data.gsub("\r","")
			year = year_data.scan(/- (.*?)<\/span>/).first.first.split.last
			matches = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr/td[@style="border-right: 1px solid #D0E0ED; padding-left: 12px"]').map(&:to_s)
			flight_arrays = matches.each_slice(2).to_a
			flight_arrays.each do |flight|
				departure_data = flight[0].gsub("\t","").gsub("\n","").gsub("\r","")
				depart_data = departure_data.scan(/<b>(.*?)<\/b>/)
				depart_airport = depart_data[0].first.strip
				depart_hour_min = am_pm_split(depart_data[1].first)
			  	depart_month_day = departure_data.scan(/- (.*?)<\/span>/).first.first.split
			  	depart_day = depart_month_day[1]
			  	depart_month = month_to_number(depart_month_day[0])
			  	depart_time = flight_date_time(depart_day, depart_month, year, depart_hour_min[:hour], depart_hour_min[:min])
			  	
			  	arrival_data = flight[1].gsub("\t","").gsub("\n","").gsub("\r","")
		  		arrival_data_port = arrival_data.scan(/<b>(.*?)<\/b>/)
		  		arrival_airport = arrival_data_port[0].first.strip
				arrival_hour_min = am_pm_split(arrival_data_port[1].first)
			  	arrival_month_day = arrival_data.scan(/- (.*?)<\/span>/).first.first.split
			  	arrival_day = arrival_month_day[1]
			  	arrival_month = month_to_number(arrival_month_day[0])
			  	arrival_time = flight_date_time(arrival_day, arrival_month, year, arrival_hour_min[:hour], arrival_hour_min[:min])
			  	seat_type = "CHEAPO"
			  	Flight.find_or_create_by_depart_time(trip_id: 72, airline_id: 103, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: seat_type )
			end
		end
	end

  	##UNITED
  	email_change_date = Date.new(2011,1,1).to_time.to_i #date that email changed
  	u_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_before: email_change_date)
	
	if u_messages.count > 0
		u_messages = u_messages.map {|message| message.body_parts.first.content}

		u_messages.each do |message|
			dom = Nokogiri::HTML(message)
			matches = dom.xpath('//*[@id="i"]/table[@style="width:511px;font:11px/15px Arial, sans-serif;"]').map(&:to_s)
			matches.each do |flight|
					flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
			  		date_split = flight_data.scan(/<span>(.*?)<\/span>/).first.first.split
			  		date_split = date_split.first.split(",")
			  		year = date_split[2]
			  		day = get_first_number(date_split[1])
			  		month = date_split[1].split("#{day}").first
			  		depart_split = flight_data.scan(/Depart: (.*?)<br>/).first.first.split
			  		depart_airport = depart_split[0]
			  		depart_hour_min = am_pm_split(depart_split[1] + depart_split[2])
			  		depart_time = flight_date_time(day, month, year, depart_hour_min[:hour], depart_hour_min[:min])
			  		arrive_split = flight_data.scan(/Arrive: (.*?)<\/td>/).first.first.split
			  		arrival_airport = arrive_split[0]
			  		arrive_hour_min = am_pm_split(arrive_split[1]+arrive_split[2])
			  		arrival_time = flight_date_time(day, month, year, arrive_hour_min[:hour], arrive_hour_min[:min])
			  		#seat_split = flight_data.scan(/Booking class: (.*?)<a/).first.first
			  		#seat_type = seat_split.scan(/<br>(.*?)<br>/).first.first
			  		seat_type = "Economy"
			  		Flight.find_or_create_by_depart_time(trip_id: 48, airline_id: 83, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: seat_type )
				
			end
		end
	end
  	

  	##OLD UNITED
  	u_oldest_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_after: email_change_date)
  	if u_oldest_messages.count > 0 
	  	u_oldest_messages = u_oldest_messages.map {|message| message.body_parts.first.content}
	  	u_oldest_messages.each do |message|
	  		dom = Nokogiri::HTML(message)
	  		matches = dom.xpath('//*[@id="flightTable"]/tr[@style="vertical-align: top;"]').map(&:to_s)
	  		matches.each do |flight|
	  			if flight.scan(/<p>(.*?)<\/p>/).count < 1 
					flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
			  		seat_type = flight_data.scan(/<td style="padding-bottom:20px;">(.*?)<\/td>/).first.first
		  			flight_data = flight_data.scan(/<td>(.*?)<\/td>/)  			
		  			departure_data = flight_data.first.first.scan(/\>(.*?)\</)

		  			depart_airport = departure_data[0].first
		  			depart_hour = departure_data[1].first
		  			depart_time_data = departure_data[3].first.split
		  			depart_month = depart_time_data[1]
		  			depart_day = depart_time_data[2]
		  			depart_year = depart_time_data[3]
		  			depart_time = create_saveable_date(depart_day, depart_month, depart_year, depart_hour)

		  			arrival_data = flight_data[1].first.scan(/\>(.*?)\</)
		  			arrival_airport = arrival_data[0].first
		  			arrival_hour = arrival_data[1].first
		  			arrival_time_data = arrival_data[3].first.split
		  			arrival_month = arrival_time_data[1]
		  			arrival_day = arrival_time_data[2]
		  			arrival_year = arrival_time_data[3]
		  			arrival_time = create_saveable_date(arrival_day, arrival_month, arrival_year, arrival_hour)

		  			Flight.find_or_create_by_depart_time(trip_id: 48, airline_id: 83, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: seat_type )
	  			end
	  		end
	  	end
	end
  	

	##Orbitz
  	email_change_date = Date.new(2011,1,1).to_time.to_i
  	o_messages = account.messages.where(from: "travelercare@orbitz.com", subject: "/Prepare For Your Trip/i", date_before: email_change_date)
  	if o_messages.count > 1
	  	o_messages = o_messages.map {|message| message.body_parts.first.content}
		o_messages.each do |message|
			dom = Nokogiri::HTML(message)
	  		matches = dom.xpath('//*[@id="emailFrame"]/tr/td/table/tr[2]/td[2]/table/tr[2]/td').map(&:to_s)
	  		matches.each do |match|
			  	match = match.gsub("\t","")
	  			match = match.gsub("\n","")
	  			match = match.gsub("\r","")	
	  			@year = match.scan(/<b>(.*?)<\/b>/)[2].first.split.last
	  			split_flights = ActionView::Base.full_sanitizer.sanitize(match).split("--------------------------------")
	  			split_flights.each do |flight|
	  				flight = flight.gsub("\t","")
		  			flight = flight.gsub("\n","")
		  			flight = flight.gsub("\r","")
		  			flight = flight.gsub("&nbsp;","")
		  			departure_data = flight.scan(/Departure(.*?)Arrival/)
		  			arrival_data = flight.scan(/Arrival(.*?)Seat/)
		  			depart_airport = departure_data.first.first.scan(/\((.*?)\)/).first.first
		  			depart_time = orbitz_time(departure_data.first.first.scan(/\:(.*?)\(/).first.first)
		  			arrival_airport = arrival_data.first.first.scan(/\((.*?)\)/).first.first
		  			arrival_time = orbitz_time(arrival_data.first.first.scan(/\:(.*?)\(/).first.first)
		  			seat_type = arrival_data.first.first.scan(/Class:(.*)/).first.first
		  			Flight.find_or_create_by_depart_time(trip_id: 28, airline_id: 43, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: seat_type )
	  			end

	  		end
	  	end
	end

	#ORBITZ OLD
	email_change_date = Date.new(2011,1,1).to_time.to_i
  	o_messages = account.messages.where(from: "travelercare@orbitz.com", subject: "/Prepare For Your Trip/i", date_after: email_change_date)
  	if o_messages.count > 1
	  	o_messages = o_messages.map {|message| message.body_parts.first.content}
	  	o_messages.each do |message|
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('/html/body/table/tr/td/table[2]/tr/td[1]/div[1]/table[2]/tr[2]/td/table/tr/td/table/tr').map(&:to_s)
		  	year_array = dom.xpath('/html/body/table/tr/td/table[2]/tr/td[2]/div[1]/table[1]/tr[3]/td/div[3]/text()')
		  	year = year_array.to_s.split[8]
		  	flight_arrays = matches.each_slice(7).to_a
		  	flight_arrays.pop
		  	flight_arrays.each do |flight|
		  		
		  		#flight data
		  		flight_date_split = ActionView::Base.full_sanitizer.sanitize(flight[0]).split
		  		word_count = flight_date_split.count
		  		if word_count == 9
			  		month = flight_date_split[3]
			  		day = flight_date_split[4]
			  	else
			  		month = flight_date_split[2]
			  		day = flight_date_split[3]
			  	end

		  		#departure data
		  		depart_array_extra = ActionView::Base.full_sanitizer.sanitize(flight[2])
		  		depart_array_extra = depart_array_extra.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
		  		depart_array = depart_array_extra.scan(/(^.*?)\|/)
		  		depart_array = depart_array.first.first
		  		depart_array = depart_array.split
		  		depart_time = "#{depart_array[0]} #{depart_array[1]}"
		  		depart_array.shift(2)
		  		depart_airport = depart_array
		  		depart_airport = depart_airport.join(" ")
		  		airport_data = flight[1]
		  		airport_data = airport_data.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
		  		airline_array = airport_data.scan(/<span class="flightNameAndNumber">(.*?)<\/span>/).first.first.split
		  		airline_array.pop
		  		airline = airline_array.join(" ")
		  		depart_time = create_saveable_date(day, month, year, depart_time)

		  		#arrival data
		  		arrival_array_extra = ActionView::Base.full_sanitizer.sanitize(flight[4])
		  		arrival_array_extra = arrival_array_extra.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
		  		arrival_array = arrival_array_extra.scan(/(^.*?)\|/)
		  		arrival_array = arrival_array.first.first
		  		arrival_array = arrival_array.split
		  		arrival_time = "#{arrival_array[0]} #{arrival_array[1]}"
		  		arrival_array.shift(2)
		  		arrival_airport = arrival_array
		  		arrival_airport = arrival_airport.join(" ")
		  		arrival_time = create_saveable_date(day, month, year, arrival_time)

		  		Flight.find_or_create_by_depart_time(trip_id: 28, airline_id: 43, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "COACH" )
		  	end	
		end
	end

	##AMERICAN AIRLINES
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com")
  	if aa_messages.count > 1
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
	  			Flight.find_or_create_by_depart_time(trip_id: 3, airline_id: 2, depart_airport: flight[:departure_airport], depart_time: flight[:departure_time], arrival_airport: flight[:arrival_airport], arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
	  		end
	  	end
	end




	##DELTA
	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com")
  	if delta_messages.count > 0
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
		  		Flight.find_or_create_by_depart_time(trip_id: 14, airline_id: 12, depart_airport: flight[:departure_airport], depart_time: flight[:departure_time], arrival_airport: flight[:arrival_airport], arrival_time: flight[:arrival_time], seat_type: flight[:seat] )
		  	end
		end
	end






  end




end