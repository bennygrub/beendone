require 'res_helper'
require 'resque-retry'
class JetblueGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  @queue = :jetblue_queue
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
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	
	##JETBLUE NEW
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip")
  	jb_messages.each do |message|
  		year = message.received_at.strftime("%Y")
  		dom = Nokogiri::HTML(message.body_parts.first.content)
  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)
  		number_of_flights = (dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').count-5)/2
  		flight_loop = (1..number_of_flights).to_a
  		flight_loop.each_with_index do |flight, index|
  			flight_index = (index + 1)*2
  			flight_data = dom.xpath("//*[@id='ticket']/div/table/tr/td/table[4]/tr[#{flight_index}]/td")
  			day_count = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.count
  			day = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-1].to_i
  			month = month_to_number(flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-2])
  			d_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.first)
  			a_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.last)
  			#d_city = flight_data[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<strong>(.*?)<\/strong>/).first.first
			#a_city = flight_data[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<strong>(.*?)<\/strong>/).last.first
	  		message_year_check(month, year)
	  		depart_time = DateTime.new(year.to_i, month.to_i, day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)
  			arrival_time = DateTime.new(year.to_i, month.to_i, day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

	  		airport_cities = flight_data[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<strong>(.*?)<\/strong>/)
	  			  		
	  		d_airport = jb_city_airport(airport_cities.first.first.split(",").first.titleize)
	  		a_airport = jb_city_airport(airport_cities.last.first.split(",").first.titleize)
	  		if Flight.where("depart_time = ?", depart_time.to_time).count > 0
	  			user_ids = Flight.where("depart_time = ?", depart_time).map{|flight| Trip.find(flight.trip_id).user_id}
	  			Flight.create(trip_id: trip.id, airline_id: airline_id, depart_airport: d_airport, depart_time: depart_time, arrival_airport: a_airport, arrival_time: arrival_time, seat_type: "Jetblue" ) unless user_ids.include? user.id
	  		else
	  			Flight.create(trip_id: trip.id, airline_id: airline_id, depart_airport: d_airport, depart_time: depart_time, arrival_airport: a_airport, arrival_time: arrival_time, seat_type: "Jetblue" )
	  		end
	  		
  		end
  	end

  	#JetBlue OLDER
  	jb_messages_old = account.messages.where(from: "mail@jetblueconnect.com", subject: "Your JetBlue E-tinerary")
  	if jb_messages_old.count > 0
	  	#jb_messages_old = jb_messages_old.map {|message| message.body_parts.first.content}
	  	jb_messages_old.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
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
		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 38, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "COACH" )
		  	end
		end
	end
  end
end