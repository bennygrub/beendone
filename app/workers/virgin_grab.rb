require 'res_helper'
require 'resque-retry'
class VirginGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  
  @queue = :virgin_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
  	airline_id = Airline.find_by_name("Virgin America").id

  	va_messages = account.messages.where(from: "virginamerica@elevate.virginamerica.com", subject: "/Virgin America Reservation/", limit: 500)
  	va_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body/table/tr[14]/td/table/tr[2]/td/table/tr').map(&:to_s)
		  	matches.shift
		  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
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
		  		depart_airport = Airport.find_by_faa(both_airports[0].first).id
		  		arrival_airport = Airport.find_by_faa(both_airports[1].first).id
		  		depart_time = Time.parse("#{date} #{both_times[0].first}")
		  		arrival_time = Time.parse("#{date} #{both_times[1].first}")

	            flight = user.flights.where(trip_id: trip.id, depart_time: depart_time.to_time).first_or_create do |f|
	              f.trip_id = trip.id
	              f.airline_id = airline_id
	              f.depart_airport = depart_airport
	              f.arrival_airport = arrival_airport
	              f.arrival_time = arrival_time
	              f.seat_type = "Virgin America"
	            end
		  	end	
	  	end
	end
	va_messages = account.messages.where(from: "no-reply@virginamerica.com", subject: "/Virgin America Reservation/", limit: 500, sort_order:"asc")
  	va_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
			matches = dom.xpath('/html/body/center/table[3]/tr[2]/td/table/tr')
			if matches.count > 0
				matches = matches.select.with_index{|x,i| x unless  i < 2  }
			  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
			  	matches.each do |match|
			  		cols = match.xpath('td')
			  		date = cols[0].text().split("-")
			  		day = date.first.to_i
			  		month = month_to_number(date[1])
			  		year = date[2].to_i

			  		depart_airport = Airport.find_by_faa(cols[2].text().scan(/\((.*?)\)/).first.first).id
			  		depart_hour = am_pm_split(cols[2].text().split(")").last)

			  		arrival_airport = Airport.find_by_faa(cols[3].text().scan(/\((.*?)\)/).first.first).id
			  		arrival_hour = am_pm_split(cols[3].text().split(")").last)

			  		arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
			  		depart_time = DateTime.new(year.to_i,month.to_i,day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

					flight = Flight.where(depart_time: depart_time).first_or_create do |f|
						f.trip_id = trip.id
						f.airline_id = airline_id
						f.depart_airport = depart_airport
						f.depart_time = depart_time
						f.arrival_airport = arrival_airport
						f.arrival_time = arrival_time
						f.seat_type = "Virgin America"
					end
			  	end
			else
				
			end	
	  	end
	end
  end
end