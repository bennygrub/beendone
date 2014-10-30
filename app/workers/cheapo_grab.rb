require 'res_helper'
require 'resque-retry'
class CheapoGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper
  @queue = :cheapo_queue
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
	c_messages = account.messages.where(from: "cheapoair@cheapoair.com", limit: 500)
	c_messages.each do |message|
		if Trip.find_by_message_id(message.message_id).nil?
			dom = Nokogiri::HTML(message.body_parts.first.content)
			year_data = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr[1]').map(&:to_s).first
			year_data = year_data.gsub("\t","")
	  		year_data = year_data.gsub("\n","")
	  		year_data = year_data.gsub("\r","")
			year = year_data.scan(/- (.*?)<\/span>/).first.first.split.last
			fare = dom.xpath('//*[@id="ctl09_ctl01_ctl00_rptConfPrice_ctl01_ctl00_trCCDetail"]/td[3]/span[2]').text().gsub("\t","").gsub("\n","").gsub("\r","").gsub(%r{\"}, '').delete(",").to_f
			matches = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr/td[@style="border-right: 1px solid #D0E0ED; padding-left: 12px"]').map(&:to_s)
			airlines = dom.xpath('//td[@style="border-right: 1px solid #D0E0ED;width:186px;"]/b')
			flight_arrays = matches.each_slice(2).to_a
			trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
			flight_arrays.each_with_index do |flight, index|
				departure_data = flight[0].gsub("\t","").gsub("\n","").gsub("\r","")
				depart_data = departure_data.scan(/<b>(.*?)<\/b>/)
				#depart_airport = depart_data[0].first.strip
				depart_code = departure_data.scan(/\(([^\)]+)\)/).last.first
				depart_airport = Airport.find_by_faa(depart_code).id
				depart_hour_min = am_pm_split(depart_data[1].first)
			  	depart_month_day = departure_data.scan(/- (.*?)<\/span>/).first.first.split
			  	depart_day = depart_month_day[1].split(",").first
			  	depart_month = month_to_number(depart_month_day[0])
			  	depart_time = DateTime.new(year.to_i, depart_month.to_i, depart_day.to_i, depart_hour_min[:hour].to_i, depart_hour_min[:min].to_i, 0, 0)
			  	
			  	arrival_data = flight[1].gsub("\t","").gsub("\n","").gsub("\r","")
		  		arrival_data_port = arrival_data.scan(/<b>(.*?)<\/b>/)
		  		
		  		arrival_code = arrival_data.scan(/\(([^\)]+)\)/).last.first
		  		arrival_airport = Airport.find_by_faa(arrival_code).id

				arrival_hour_min = am_pm_split(arrival_data_port[1].first)
			  	arrival_month_day = arrival_data.scan(/- (.*?)<\/span>/).first.first.split
			  	arrival_day = arrival_month_day[1].split(",").first
			  	arrival_month = month_to_number(arrival_month_day[0])
			  	
			  	arrival_time = DateTime.new(year.to_i, arrival_month.to_i, arrival_day.to_i, arrival_hour_min[:hour].to_i, arrival_hour_min[:min].to_i, 0, 0)
			  	airline = airlines[index].text().to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip

				begin
	  				airline_id = Airport.find_by_name(airline).id
	  			rescue Exception => e
	  				Rollbar.report_message("Airline", "error", :message_id => message.message_id, :airline => airline, :company => "cheapo")
	  				airline_id = Airline.find_by_name("Cheapo Air").id
		  		end

				flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
	  				f.trip_id = trip.id
	  				f.airline_id = airline_id
	  				f.depart_airport = depart_airport
	  				f.depart_time = depart_time
	  				f.arrival_airport = arrival_airport
	  				f.arrival_time = arrival_time
	  				f.seat_type = fare
				end
			end
		end#No other trips 
	end
  end
end