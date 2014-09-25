require 'res_helper'
require 'resque-retry'
class JetblueGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  @queue = :jetblue_queue
  @retry_limit = 5
  @retry_delay = 30

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	
	##JETBLUE NEW
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip")
  	if jb_messages.count > 0
	  	jb_messages = jb_messages.map {|message| message.body_parts.first.content}
	  	jb_messages.each do |message|
	  		trip = Trip.create(user_id: user.id)
	  		@message = message
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').map(&:to_s)
		  	matches.pop(5)
		  	matches.shift
		  	matches = matches.select.each_with_index { |str, i| i.even? }
		  	#match = matches[1]
		  	matches.each do |match|
		  		both_airports = match.scan(/<strong>(.*?)<\/strong>/)	  		
		  		depart_city = both_airports.first.first.split(",").first.titleize
		  		if depart_city == "New York Jfk" || depart_city == "New York Lga"
		  			depart_nyc = depart_city.split(" ").last.upcase
		  			depart_airport = Airport.find_by_faa(depart_nyc)
		  		else
		  			depart_airport = Airport.where("city = ?", depart_city).first.id
		  		end
		  		
		  		arrival_city = both_airports.second.first.split(",").first.titleize
		  		if arrival_city == "New York Jfk" || arrival_city == "New York Lga"
		  			arrival_city_nyc = arrival_city.split(" ").last.upcase

		  			arrival_airport = Airport.find_by_faa(arrival_city_nyc).id
		  		else
		  			arrival_airport = Airport.where("city = ?", arrival_city).first.id
		  		end
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

		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip_id, airline_id: 1, depart_airport: depart_airport, depart_time: departure_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "Jetblue" )
		  	end
	  	end
	end

  	#JetBlue OLDER
  	jb_messages_old = account.messages.where(from: "mail@jetblueconnect.com", subject: "Your JetBlue E-tinerary")
  	if jb_messages_old.count > 0
	  	jb_messages_old = jb_messages_old.map {|message| message.body_parts.first.content}
	  	jb_messages_old.each do |message|
	  		trip = Trip.create(user_id: user.id)
	  		dom = Nokogiri::HTML(message)
		  	matches = dom.xpath('/html/body/div/table/tr[11]/td/table/tr').map(&:to_s)
		  	matches.shift(2)
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
		  			depart_airport = Airport.where("city = ?", depart_city).first.id
		  		end
		  		arrival_city = flight_array[3].first.split(",").first
		  		if arrival_city == "New York"
		  			arrival_code = flight_array[3].first.split(",").second.split(" ").first
		  			arrival_airport = Airport.find_by_faa(arrival_code).id
		  		else
		  			arrival_airport = Airport.where("city = ?", arrival_city).first.id
		  		end
		  		#d_split = departure_data.split
		  		#d_split.pop
		  		#depart_airport = d_split.join(" ")
		  		arrival_data = flight_array[3].first
		  		arrival_time = arrival_data.split.pop
		  		#a_split = arrival_data.split
		  		#a_split.pop
		  		#arrival_airport = a_split.join(" ")
		  		arrival_time = old_jb_time(date,arrival_time)
		  		depart_time = old_jb_time(date,depart_time)
		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 1, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "COACH" )
		  	end
		end
	end
  end
end