require 'res_helper'
require 'resque-retry'
class EmiratesGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  
  @queue = :emirates_queue
  @retry_limit = 5
  @retry_delay = 30

  def perform
  	user_id = options['user_id']
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: "annievenezia@gmail.com").first
  	airline_id = Airline.find_by_name("Emirates").id
  	#get messages from Virgin and pick the html
  	sw_messages = account.messages.where(from: "do-not-reply@emirates.com", subject: "/Booking Confirmation/")
  	sw_messages.each do |message|
  		dom = Nokogiri::HTML(message.body_parts.first.content)
  		flight_rows = dom.xpath('//tr[@id="departRow" or @id="returnRow"]')
  		flight_rows = flight_rows.select{|f| f unless f.xpath('td[@class="connection"]').count > 0}
  		flight_rows = flight_rows.each_slice(2).to_a
  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "Emirates")
  		flight_rows.each do |flight|
  			depart_col = flight[0].xpath('td')
  			depart_date_row = depart_col[1].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<span>(.*?)<\/span>/).first.first.split
  			depart_day = depart_date_row.first
  			depart_month = month_to_number(depart_date_row[1])
  			depart_year = "20#{depart_date_row[2]}".to_i
  			depart_hour = am_pm_split(depart_col[2].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, ''))
  			depart_airport = Airport.find_by_faa(depart_col[3].text().scan(/\((.*?)\)/).first.first)
  			
  			arrival_col = flight[1].xpath('td')
  			arrival_date_row = arrival_col[0].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<span>(.*?)<\/span>/).first.first.split
  			arrival_day = arrival_date_row.first
  			arrival_month = month_to_number(arrival_date_row[1])
  			arrival_year = "20#{arrival_date_row[2]}".to_i
  			arrival_hour = am_pm_split(arrival_col[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, ''))
  			arrival_airport = Airport.find_by_faa(arrival_col[2].text().scan(/\((.*?)\)/).first.first)

  			depart_time = DateTime.new(depart_year.to_i,depart_month.to_i,depart_day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)
  			arrival_time = DateTime.new(arrival_year.to_i,arrival_month.to_i,arrival_day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)

            flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
              f.trip_id = trip.id
              f.airline_id = airline_id
              f.depart_airport = depart_airport
              f.depart_time = depart_time
              f.arrival_airport = arrival_airport
              f.arrival_time = arrival_time
              f.seat_type = "Emirates"
            end
  		end
  	end
	#completed("Finished!")
  end
end