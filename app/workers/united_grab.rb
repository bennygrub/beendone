require 'res_helper'
class UnitedGrab
  extend ResHelper
  @queue = :united_queue

  def self.perform(user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first

	email_change_date = Date.new(2011,1,1).to_time.to_i #date that email changed
  	u_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_before: email_change_date)
	
	if u_messages.count > 0
		u_messages = u_messages.map {|message| message.body_parts.first.content}

		u_messages.each do |message|
			trip = Trip.create(user_id: user.id)
			dom = Nokogiri::HTML(message)
			matches = dom.xpath('//*[@id="i"]/table[@style="width:511px;font:11px/15px Arial, sans-serif;"]').map(&:to_s)
			matches.each do |flight|
					flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
			  		date_split = flight_data.scan(/<span>(.*?)<\/span>/).first.first.split
			  		date_split = date_split.first.split(",")
			  		year = date_split[2]
			  		day = get_first_number(date_split[1])
			  		month = date_split[1].split("#{day}").first
			  		depart_split = flight_data.scan(/Depart: (.*?)<br>/).first.first.split
			  		depart_airport = depart_split[0]
			  		depart_hour_min = am_pm_split(depart_split[1] + depart_split[2])
			  		depart_time = flight_date_time(day, month, year, depart_hour_min[:hour], depart_hour_min[:min])
			  		arrive_split = flight_data.scan(/Arrive: (.*?)<\/td>/).first.first.split
			  		arrival_airport = arrive_split[0]
			  		arrive_hour_min = am_pm_split(arrive_split[1]+arrive_split[2])
			  		arrival_time = flight_date_time(day, month, year, arrive_hour_min[:hour], arrive_hour_min[:min])
			  		#seat_split = flight_data.scan(/Booking class: (.*?)<a/).first.first
			  		#seat_type = seat_split.scan(/<br>(.*?)<br>/).first.first
			  		seat_type = "Economy"
			  		Flight.find_or_create_by_depart_time(trip_id: trip.id, airline_id: 83, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: depart_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: arrival_time, seat_type: seat_type )
				
			end
		end
	end
  	

  	##OLD UNITED
  	u_oldest_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_after: email_change_date)
  	if u_oldest_messages.count > 0 
	  	u_oldest_messages = u_oldest_messages.map {|message| message.body_parts.first.content}
	  	u_oldest_messages.each do |message|
	  		trip = Trip.create(user_id: user.id)
	  		dom = Nokogiri::HTML(message)
	  		matches = dom.xpath('//*[@id="flightTable"]/tr[@style="vertical-align: top;"]').map(&:to_s)
	  		matches.each do |flight|
	  			if flight.scan(/<p>(.*?)<\/p>/).count < 1 
					flight_data = flight.gsub("\t","").gsub("\n","").gsub("\r","")
			  		seat_type = flight_data.scan(/<td style="padding-bottom:20px;">(.*?)<\/td>/).first.first
		  			flight_data = flight_data.scan(/<td>(.*?)<\/td>/)  			
		  			departure_data = flight_data.first.first.scan(/\>(.*?)\</)

		  			depart_airport = departure_data[0].first
		  			depart_hour = departure_data[1].first
		  			depart_time_data = departure_data[3].first.split
		  			depart_month = depart_time_data[1]
		  			depart_day = depart_time_data[2]
		  			depart_year = depart_time_data[3]
		  			depart_time = create_saveable_date(depart_day, depart_month, depart_year, depart_hour)

		  			arrival_data = flight_data[1].first.scan(/\>(.*?)\</)
		  			arrival_airport = arrival_data[0].first
		  			arrival_hour = arrival_data[1].first
		  			arrival_time_data = arrival_data[3].first.split
		  			arrival_month = arrival_time_data[1]
		  			arrival_day = arrival_time_data[2]
		  			arrival_year = arrival_time_data[3]
		  			arrival_time = create_saveable_date(arrival_day, arrival_month, arrival_year, arrival_hour)

		  			Flight.find_or_create_by_depart_time(trip_id: trip.id, airline_id: 83, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: depart_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: arrival_time, seat_type: seat_type )
	  			end
	  		end
	  	end
	end
  end
end