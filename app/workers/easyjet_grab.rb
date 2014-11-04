require 'res_helper'
require 'resque-retry'
class EasyjetGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  
  @queue = :easyjet_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
  	airline_id = Airline.find_by_name("easyJet").id
  	#get messages from Virgin and pick the html
  	easy_messages = account.messages.where(from: "donotreply@easyjet.com", subject: "/easyJet booking reference:/")
  	
  	easy_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
  			dom = Nokogiri::HTML(message.body_parts.first.content)
  			rows = dom.xpath('//*[@id="SidePanel"]/table/tr/td/table/tr[6]/td/table/tr')
  			if rows.count > 0
  				depart_row = rows[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split
  				x = depart_row.count
  				depart_hour = am_pm_split(depart_row[x-1])
  				depart_year = depart_row[x-2]
  				depart_month = month_to_number(depart_row[x-3])
  				depart_day = depart_row[x-4]
  				depart_time = DateTime.new(depart_year.to_i,depart_month.to_i,depart_day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

				arrival_row = rows[2].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split
  				x = arrival_row.count
  				arrival_hour = am_pm_split(arrival_row[x-1])
  				arrival_year = arrival_row[x-2]
  				arrival_month = month_to_number(arrival_row[x-3])
  				arrival_day = arrival_row[x-4]

	  			arrival_time = DateTime.new(arrival_year.to_i,arrival_month.to_i,arrival_day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)

  				airports = dom.xpath('//*[@id="SidePanel"]/table/tr/td/table/tr[6]/td/table/tr[1]/td[2]').text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split("to")
  				depart_city = airports.first
  				arrival_city = airports.last

  				trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create

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

				flight = Flight.where(depart_time: depart_time).first_or_create do |f|
					f.trip_id = trip.id
					f.airline_id = airline_id
					f.depart_airport = depart_airport
					f.depart_time = depart_time
					f.arrival_airport = arrival_airport
					f.arrival_time = arrival_time
					f.seat_type = "Easy Jet"
				end
				  			
				FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
				FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
			end
		end
  	end
  end
end