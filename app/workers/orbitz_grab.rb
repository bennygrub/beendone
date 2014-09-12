require 'res_helper'
class OrbitzGrab
  extend ResHelper
  @queue = :orbitz_queue

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first

	email_change_date = Date.new(2011,1,1).to_time.to_i
  	o_messages = account.messages.where(from: "travelercare@orbitz.com", subject: "/Prepare For Your Trip/i", date_before: email_change_date)
  	if o_messages.count > 0
	  	o_messages = o_messages.map {|message| message.body_parts.first.content}
		o_messages.each do |message|
			trip = Trip.create(user_id: user.id)
			dom = Nokogiri::HTML(message)
	  		matches = dom.xpath('//*[@id="emailFrame"]/tr/td/table/tr[2]/td[2]/table/tr[2]/td').map(&:to_s)
	  		matches.each do |match|
			  	match = match.gsub("\t","").gsub("\n","").gsub("\r","")
	  			@year = match.scan(/<b>(.*?)<\/b>/)[2].first.split.last
	  			split_flights = ActionView::Base.full_sanitizer.sanitize(match).split("--------------------------------")
	  			split_flights.each do |flight|
	  				flight = flight.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
		  			departure_data = flight.scan(/Departure(.*?)Arrival/)
		  			arrival_data = flight.scan(/Arrival(.*?)Seat/)
		  			depart_airport = departure_data.first.first.scan(/\((.*?)\)/).first.first
		  			depart_time = orbitz_time(departure_data.first.first.scan(/\:(.*?)\(/).first.first)
		  			arrival_airport = arrival_data.first.first.scan(/\((.*?)\)/).first.first
		  			arrival_time = orbitz_time(arrival_data.first.first.scan(/\:(.*?)\(/).first.first)
		  			seat_type = arrival_data.first.first.scan(/Class:(.*)/).first.first
		  			Flight.find_or_create_by_depart_time(trip_id: trip.id, airline_id: 43, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: seat_type )
	  			end

	  		end
	  	end
	end

	#ORBITZ OLD
	email_change_date = Date.new(2011,1,1).to_time.to_i
  	o_messages = account.messages.where(from: "travelercare@orbitz.com", subject: "/Prepare For Your Trip/i", date_after: email_change_date)
  	if o_messages.count > 0
	  	o_messages = o_messages.map {|message| message.body_parts.first.content}
	  	o_messages.each do |message|
	  		trip = Trip.create(user_id: user.id)
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

		  		Flight.find_or_create_by_depart_time(trip_id: trip.id, airline_id: 43, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "COACH" )
		  	end	
		end
	end
  end
end