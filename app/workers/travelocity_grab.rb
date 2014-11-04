require 'res_helper'
require 'resque-retry'
class TravelocityGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper

  @queue = :travelocity_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
  	if Rails.env.production?
  		contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	else
  		contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	end
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
  	airline_id = Airline.find_by_name("Travelocity").id
  	#get messages from Virgin and pick the html
  	to_messages = account.messages.where(from: "travelocity@travelocity.com", subject: "/Travelocity Reservation/")
  	to_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
  			dom = Nokogiri::HTML(message.body_parts.first.content)
  			matches = dom.xpath('//table[@class="tbl_itin_flt"]')
  			matches = matches.select.with_index{|x, i| x unless i > (matches.count-2)}
  			trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
  			matches.each do |match|
  				rows = match.xpath('tr')
  				date = rows[1].xpath('td')[0].text().split(",")
  				year = date.last.to_i
  				day = date[1].match(/\d+/).to_s
  				month = month_to_number(date[1].split(day).first)
  				airports = rows[1].text().scan(/\((.*?)\)/)
  				depart_airport = Airport.find_by_faa(airports.first.first).id
  				arrival_airport = Airport.find_by_faa(airports.last.first).id
  				times = rows[2].xpath('td')[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip
  				depart_hour = am_pm_split(times.scan(/Depart: (.*?)Arrive/).first.first)
  				arrival_hour = am_pm_split(times.scan(/Arrive: (.*)/).first.first)
		  		
		  		arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
		  		depart_time = DateTime.new(year.to_i,month.to_i,day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)
				
				flight = Flight.where(depart_time: depart_time).first_or_create do |f|
					f.trip_id = trip.id
					f.airline_id = airline_id
					f.depart_airport = depart_airport
					f.depart_time = depart_time
					f.arrival_airport = arrival_airport
					f.arrival_time = arrival_time
					f.seat_type = "Travelocity"
				end
  			end
  		end
  end
end