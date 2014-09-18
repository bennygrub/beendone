require 'res_helper'
class CheapoGrab
  extend ResHelper
  @queue = :cheapo_queue

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	c_messages = account.messages.where(from: "cheapoair@cheapoair.com", subject: '/AIR TICKET/i')
	if c_messages.count > 0
		c_messages = c_messages.map {|message| message.body_parts.first.content}
		
		c_messages.each do |message|
			trip = Trip.create(user_id: user.id)
			dom = Nokogiri::HTML(message)
			year_data = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr[1]').map(&:to_s).first
			year_data = year_data.gsub("\t","")
	  		year_data = year_data.gsub("\n","")
	  		year_data = year_data.gsub("\r","")
			year = year_data.scan(/- (.*?)<\/span>/).first.first.split.last
			matches = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr/td[@style="border-right: 1px solid #D0E0ED; padding-left: 12px"]').map(&:to_s)
			flight_arrays = matches.each_slice(2).to_a
			flight_arrays.each do |flight|
				departure_data = flight[0].gsub("\t","").gsub("\n","").gsub("\r","")
				depart_data = departure_data.scan(/<b>(.*?)<\/b>/)
				#depart_airport = depart_data[0].first.strip
				depart_code = departure_data.scan(/\(([^\)]+)\)/).last.first
				depart_hour_min = am_pm_split(depart_data[1].first)
			  	depart_month_day = departure_data.scan(/- (.*?)<\/span>/).first.first.split
			  	depart_day = depart_month_day[1]
			  	depart_month = month_to_number(depart_month_day[0])
			  	depart_time = flight_date_time(depart_day, depart_month, year, depart_hour_min[:hour], depart_hour_min[:min])
			  	
			  	arrival_data = flight[1].gsub("\t","").gsub("\n","").gsub("\r","")
		  		arrival_data_port = arrival_data.scan(/<b>(.*?)<\/b>/)
		  		#arrival_airport = arrival_data_port[0].first.strip
		  		arrival_code = arrival_data.scan(/\(([^\)]+)\)/).last.first
				arrival_hour_min = am_pm_split(arrival_data_port[1].first)
			  	arrival_month_day = arrival_data.scan(/- (.*?)<\/span>/).first.first.split
			  	arrival_day = arrival_month_day[1]
			  	arrival_month = month_to_number(arrival_month_day[0])
			  	arrival_time = flight_date_time(arrival_day, arrival_month, year, arrival_hour_min[:hour], arrival_hour_min[:min])
			  	seat_type = "CHEAPO"
			  	Flight.find_or_create_by_depart_time(trip_id: trip, airline_id: 103, depart_airport: Airport.find_by_faa(depart_code).id, depart_time: depart_time, arrival_airport: Airport.find_by_faa(arrival_code).id, arrival_time: arrival_time, seat_type: seat_type )
			end
		end
	end
  end
end