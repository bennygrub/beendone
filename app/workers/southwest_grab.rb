require 'res_helper'
require 'resque-retry'
class SouthwestGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :southwest_queue
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


  	airline_id = Airline.find_by_name("Southwest Airlines").id
  	#get messages from Virgin and pick the html
  	sw_messages = account.messages.where(from: "SouthwestAirlines@luv.southwest.com", subject: "/Southwest Airlines Confirmation-/")
  	if sw_messages.count > 0
	  	sw_messages.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "SouthWest")
	  		year = message.received_at.strftime("%Y")
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		flights_array = dom.xpath('//div[@style="line-height: 14px; font-family: arial,verdana; color: #000000; font-size: 11px"]').map(&:to_s).each_slice(3).to_a
	  		flights_array.each do |flight|
	  			flight_date = flight[0].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/>(.*?)</).first.first.split
	  			month = month_to_number(flight_date[1])
	  			day = flight_date[2]
	  			depart_airport = Airport.find_by_faa(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).first.first).id
	  			arrival_airport = Airport.find_by_faa(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).last.first).id
	  			d_time = am_pm_split(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/b>(.*?)<\/b/)[1].first)
	  			a_time = am_pm_split(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/b>(.*?)<\/b/)[3].first)
	  			depart_time = DateTime.new(year.to_i, month.to_i, day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)
	  			arrival_time = DateTime.new(year.to_i, month.to_i, day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

	  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: airline_id, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "Southwest" )
	  		end
	  	end
	end
  end
end