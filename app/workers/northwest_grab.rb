require 'res_helper'
require 'resque-retry'
class NorthwestGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  @queue = :northwest_queue
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


  	airline_id = Airline.find_by_name("Northwest Airlines").id
  	#get messages from Virgin and pick the html
  	nw_messages = account.messages.where(from: "Northwest.Airlines@nwa.com", subject: "/nwa.com Reservations Air Purchase Confirmation/", limit: 500)
  	nw_messages.each do |message|	  		
  		if Trip.find_by_message_id(message.message_id).nil?
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		year = message.received_at.strftime("%Y")
	  		cost = dom.xpath('//*[@id="totalCost"]').to_s.scan(/Price:(.*?)</).first.first.gsub(" ", "")
	  		legdata = dom.xpath('/html/body/div[@class="legdata"]')
	  		flights_array = legdata.each_slice(5).to_a
	  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
	  		flights_array.each do |flight|
	  			depart_airport = Airport.find_by_faa(flight[1].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).first.first).id
	  			depart_time_array = flight[1].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\)(.*?)</).first.first.gsub(".","").gsub(",","").split
	  			d_month = month_to_number(depart_time_array[1])
	  			d_day = depart_time_array[2]
	  			d_time = am_pm_split(depart_time_array[3] + depart_time_array[4])
	  			depart_time = DateTime.new(year.to_i, d_month.to_i, d_day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)

	  			arrival_airport = Airport.find_by_faa(flight[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).first.first).id
	  			arrival_time_array = flight[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\)(.*?)</).first.first.gsub(".","").gsub(",","").split
	  			a_month = month_to_number(arrival_time_array[1])
	  			a_day = arrival_time_array[2]
	  			a_time = am_pm_split(arrival_time_array[3] + arrival_time_array[4])
	  			year = message_year_check(a_month, year)

	  			arrival_time = DateTime.new(year.to_i, a_month.to_i, a_day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

				flight = Flight.where(depart_time: depart_time).first_or_create do |f|
	  				f.trip_id = trip.id
	  				f.airline_id = airline_id
	  				f.depart_airport = depart_airport
	  				f.depart_time = depart_time
	  				f.arrival_airport = arrival_airport
	  				f.arrival_time = arrival_time
	  				f.seat_type = "Northwest"
				end
	  		end
	  	end
  	end
  end
end