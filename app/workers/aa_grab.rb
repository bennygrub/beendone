require 'res_helper'
require 'resque-retry'
class AaGrab
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  extend ResHelper
  @queue = :aa_queue
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
	airline_id = Airline.find_by_name("American Airlines").id
	##AMERICAN AIRLINES
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com")
  	if aa_messages.count > 0
	  	#aa_messages = aa_messages.map {|message| message.body_parts.first.content}
	  	aa_messages.each do |message|
	  		#email_message = message.body_parts.first.content
	  		dom = Nokogiri::HTML(message.body_parts.where(type: 'text/html').first.content)
	  		flight_arrays = dom.xpath('//td[@valign="center" and @style="FONT-WEIGHT: normal; FONT-SIZE: 12px; COLOR: #607982; font-family:Arial;"]').each_slice(5).to_a
	  		if flight_arrays.count > 0
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		flight_arrays.each do |flight|
		  			depart_city = flight[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/>(.*?)<br>/).first.first.strip
		  			depart_day_month = flight[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<br>/).first.first.strip.split().last
		  			depart_day = depart_day_month.match(/\d+/).to_s
		  			depart_month = month_to_number(depart_day_month.split(depart_day).last)
		  			depart_time = am_pm_split(flight[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<\/td>/).first.first.split.pop(2).join(""))

		  			arrival_time = am_pm_split(flight[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<\/td>/).first.first.split.pop(2).join(""))
		  			arrival_city = flight[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/Arial;>(.*?)<br>/).first.first.strip

		  			if flight[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<br>/).first.first.strip.split().last.nil?
		  				arrival_day = depart_day
		  				arrival_month = depart_month
		  			else
		  				arrival_day_month = flight[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<br>/).first.first.strip.split().last
		  				arrival_day = arrival_day_month.match(/\d+/).to_s
		  				arrival_month = month_to_number(depart_day_month.split(depart_day).last)
		  			end
		  			
		  			year = message.received_at.strftime("%Y").to_i
		  			year = year + 1 if message.received_at.strftime("%M").to_i == 12

		  			d_time = DateTime.new(year, depart_month.to_i, depart_day.to_i, depart_time[:hour].to_i,depart_time[:min].to_i, 0, 0)
		  			a_time = DateTime.new(year, arrival_month.to_i, arrival_day.to_i, arrival_time[:hour].to_i,arrival_time[:min].to_i, 0, 0)

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

					flight = Flight.where(trip_id: trip.id, depart_time: d_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = a_time
		  				f.seat_type = "American"
					end
			  			
			  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
		  		end
		  	else
		  		flight_trs = dom.xpath('//table[@width="100%" and @cellspacing="0" and @cellpadding = "0" and @style="font-family:Arial,Verdana,Helvetica;font-size:8pt"]/tr')
		  		flight_rows = flight_trs.select{|tr| tr.attributes["bgcolor"].nil?}
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		flight_rows.each do |row|
		  			cells = row.xpath('td')
		  			depart_city = cells[2].text().strip
		  			depart_time = am_pm_split(cells[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<\/td>/).first.first)
		  			depart_day_month = cells[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/00007C;>(.*?)<br>/).first.first.split.last
		  			depart_day = depart_day_month.match(/\d+/).to_s
		  			depart_month = month_to_number(depart_day_month.split(depart_day).last)

		  			arrival_city = cells[4].text().strip
		  			if cells[5].text().strip.split.count == 2
		  				arrival_time = am_pm_split(cells[5].text().strip)
		  				arrival_day = depart_day
		  				arrival_month = depart_month
		  			else
						arrival_time = am_pm_split(cells[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<br>(.*?)<\/td>/).first.first)
			  			arrival_day_month = cells[3].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/00007C;>(.*?)<br>/).first.first.split.last
			  			arrival_day = arrival_day_month.match(/\d+/).to_s
		  			end
		  			
		  			year = message.received_at.strftime("%Y").to_i
		  			year = year + 1 if message.received_at.strftime("%M").to_i == 12

		  			d_time = DateTime.new(year, depart_month.to_i, depart_day.to_i, depart_time[:hour].to_i,depart_time[:min].to_i, 0, 0)
		  			a_time = DateTime.new(year, arrival_month.to_i, arrival_day.to_i, arrival_time[:hour].to_i,arrival_time[:min].to_i, 0, 0)

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

					flight = Flight.where(trip_id: trip.id, depart_time: d_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = a_time
		  				f.seat_type = "American"
					end
			  			
			  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix

		  		end
		  	end
	  	end
	end
  end
end