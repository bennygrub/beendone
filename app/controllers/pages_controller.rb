class PagesController < ApplicationController  
  require 'nokogiri'
  require 'open-uri'
  require 'chronic'
  require 'ostruct'

  def playground

  end

  def home
  	@home_page = true
  	if current_user
  		redirect_to current_user
  	end
  end
  
  def how 

  end

  def all
  	Resque.enqueue(SearchAll, current_user.id, 0)
  end

  def about
  end
  def delta
  	user_id = 18
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')  	
  	#get the correct account
  	account = contextio.accounts.where(email: "nwcooper@gmail.com").first
  	airline_id = Airline.find_by_name("Delta Air Lines").id
	##DELTA
	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com", limit: 500)
  	delta_messages.each do |message|
	  	if Trip.find_by_message_id(message.message_id).nil?
		  	year = message.received_at.strftime('%Y')
		  	dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body//pre/text()').map(&:to_s)
		  	
			#get overall data
		  	fare = matches[2].scan(/Fare: (.+)/).first.first.strip.split(/\s+/).first
		  	issue_data = matches.last.match(/Issue date:(.*)/).to_s
		  	issue_date = split_by_space(issue_data)[2]
		  	issue_year = issue_date.split(//).last(2).join("").to_i
		  	
		  	matches = dom.xpath('/html/body//pre')
		  	flight_doubles = matches[1].text().split(/\r?\n/).select{|m| m if m.scan(/AR/).count > 0 || m.scan(/LV/).count > 0 }
		  	flight_array = flight_doubles.each_slice(2).to_a
		  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  	
		  	flight_array.each do |flight|
		  		depart_data = flight[0]
		  		date = depart_data.chars.each_slice(9).map(&:join).first.split.last
		  		day = date.match(/\d+/).to_s
		  		month = month_to_number(date.split(day).last)
		  		lv = depart_data.scan(/LV(.*)/).first.first.strip
		  		depart_city = lv.chars.each_slice(14).map(&:join).first.strip

		  		ar = flight[1].strip
		  		arrival_city = ar.split('AR', 2)[1].strip.chars.each_slice(14).map(&:join).first.strip
		  		depart_hour = am_pm_split(lv.chars.each_slice(14).map(&:join)[1].split.first)
		  		arrival_hour = am_pm_split(ar.split('AR', 2)[1].strip.chars.each_slice(14).map(&:join)[1].split.first)
		  		
		  		
		  		begin
			  		arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
		  			depart_time = DateTime.new(year.to_i,month.to_i,day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)	
		  		rescue Exception => e
		  			arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i-1,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
		  			depart_time = DateTime.new(year.to_i,month.to_i,day.to_i-1,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)
		  		end
		  		
				
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
						f.seat_type = "Delta"
				end
		  			
		  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
		  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
		  	end
		end
	end
	delta_messages = account.messages.where(from: "DeltaAirLines@e.delta.com", limit: 5000)
  	no_subjects = ["It's Time To Check-In", "Your SkyMiles Account", "Your SkyMiles Password", "Reminder: Your January SkyMiles STATEMENT", "Reminder: Your February SkyMiles STATEMENT", "Reminder: Your March SkyMiles STATEMENT","Reminder: Your April SkyMiles STATEMENT", "Reminder: Your May SkyMiles STATEMENT", "Reminder: Your June SkyMiles STATEMENT", "Reminder: Your July SkyMiles STATEMENT", "Reminder: Your September SkyMiles STATEMENT", "Reminder: Your October SkyMiles STATEMENT", "Reminder: Your November SkyMiles STATEMENT", "Reminder: Your December SkyMiles STATEMENT", "Your January SkyMiles STATEMENT","Your February SkyMiles STATEMENT", "Your March SkyMiles STATEMENT", "Your April SkyMiles STATEMENT", "Your May SkyMiles STATEMENT", "Your June SkyMiles STATEMENT", "Your July SkyMiles STATEMENT", "Your August SkyMiles STATEMENT", "Your September SkyMiles STATEMENT", "Your October SkyMiles STATEMENT", "Your Novemeber SkyMiles STATEMENT", "Your December SkyMiles STATEMENT"]
  	good_messages = delta_messages.select{|m| m unless no_subjects.include?(m.subject)}
  	good_messages.each do |message|
	  	if Trip.find_by_message_id(message.message_id).nil?
		  	dom = Nokogiri::HTML(message.body_parts.first.content)
		  	year = message.received_at.strftime("%Y")
		  	flights = dom.xpath('/html/body/table/tr/td/table[3]/tr/td[2]/table[4]/tr/td[2]/table[6]/tr')
		  	if flights.count == 10 || flights.count == 5
		  		flight_array = dom.xpath('/html/body/table/tr/td/table[3]/tr/td[2]/table[4]/tr/td[2]/table[6]/tr').each_slice(5).to_a
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		flight_array.each_with_index do |f, i|
		  			x = i * 5
			  		flight_date = flights[x].xpath('td[3]').text().split[1]
			  		flight_day = flight_date.match(/\d+/).to_s
			  		flight_month = month_to_number(flight_date.split(flight_day)[1])
			  		flight_depart_time = am_pm_split(flights[x+2].xpath('td[3]').text().split[1])
			  		depart_city = flights[x+2].xpath('td[5]').text()
			  		flight_arrival_time = am_pm_split(flights[x+2].xpath('td[7]').text().split[1])
			  		arrival_city = flights[x+2].xpath('td[9]').text()

			  		depart_time = DateTime.new(year.to_i, flight_month.to_i, flight_day.to_i, flight_depart_time[:hour].to_i,flight_depart_time[:min].to_i, 0, 0)
			  		arrival_time = DateTime.new(year.to_i, flight_month.to_i, flight_day.to_i, flight_arrival_time[:hour].to_i,flight_arrival_time[:min].to_i, 0, 0)
					
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
		  				arrival_airport = Airport.find_by_city(arrival_city.titleize).issue_date
		  				aeflightfix = false
		  			rescue Exception => e
		  				ae = city_error_check(arrival_city, 2, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, arrival_city, airline_id, user_id) if ae.airport_id.blank?
		  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
		  				aeflightfix = true if ae.airport_id.blank? #set flag
			  		end

				  	flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.depart_time = depart_time
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = arrival_time
		  				f.seat_type = "Delta"
					end
			  			
			  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix

			  	end


			else
				
			end
		end
	end
  end
  def contact
  	#auth into contextio
  	user = User.find(18)
  	user_id = 18
  	#auth into contextio
	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	account = contextio.accounts.where(email: "carly.creighton@gmail.com").first
	airline_id = Airline.find_by_name("American Airlines").id
	##AMERICAN AIRLINES
  	aa_messages = account.messages.where(from: "notify@aa.globalnotifications.com", subject: "/E-Ticket Confirmation/", limit: 500)
  	#no_subjects = ["American Airlines Upgrade Notification"]
  	#good_messages = aa_messages.select{|m| m unless no_subjects.include?(m.subject)}
  	aa_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		email = message.body_parts.where(type: 'text/html')
	  		if email.count.nil?
	  			html = message.body_parts.first.content
	  			binding.pry
	  		else
	  			html = email.first.content
	  		end
	  		dom = Nokogiri::HTML(html)
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

					flight = user.flights.where(trip_id: trip.id, depart_time: d_time).first_or_create do |f|
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
		  			if cells.count > 3
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

						flight = Flight.where(depart_time: d_time).first_or_create do |f|
			  				f.trip_id = trip.id
			  				f.airline_id = airline_id
			  				f.depart_airport = depart_airport
			  				f.depart_time = d_time
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
  def usairways
  	user_id = 18
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first

  	email_change_date = Date.new(2014,1,1).to_time.to_i

  	airline_id = Airline.where("name = ?", "USAir").first.id
  	#US AIRWAYS NEW EMAIL STARTING 2014
  	#get messages from delta and pick the html
  	usa_messages = account.messages.where(from: "reservations@email-usairways.com", limit: 500)
  	usa_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body/div/table/tr[2]/td/table/tr[1]/td/table[5]/tr')
		  	important = matches.map{|match| match unless match.attributes["style"].blank?}.compact
		  	split_points = important.map{|match| match if match.attributes["style"].value == "padding-top:17px;"}.each_with_index.map{|a, index| index  unless a.nil?}.compact.map{|a| a unless a == 0}.compact
		  	if split_points.count > 0
			  	day_array = []
			  	split_points.each_with_index do |split, index|
			  		if split_points.count == 1
			  			day_array << important[0...split]
			  			day_array << important[split...important.count]
			  		elsif index == 0#first iteration if there is more than 1 split point
			  			day_array << important[0...split]
			  		elsif index < split_points.count-1#2nd, 3rd, 4th iterations
			  			day_array << important[split_points[index-1]...split]
			  		else#last split going to end of array
			  			day_array << important.each_slice(split).to_a.last
			  		end
			  	end
			  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
			  	#day_array is array of the flights by day of travel
			  	day_array.each do |day|
			  		flight_count = (day.count-2)/2 #counts the number of flights that day
			  		date_month_day_year = day[1].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").scan(/font:normal 12px Arial, Helvetica, sans-serif;(.*?)<\/span>/).first.first.gsub('">','').split
			  		flight_count_array = [*1..flight_count]
			  		flight_count_array.each_with_index do |value, index|
				  		y = (3)+(index*2)
				  		depart_airport = Airport.find_by_faa(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").scan(/padding-left:3px;(.*?)<\/span>/)[0].first.gsub('">','').gsub(" ", "")).id
				  		arrival_airport = Airport.find_by_faa(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").scan(/padding-left:3px;(.*?)<\/span>/)[1].first.gsub('">','').gsub(" ", "")).id
				  		depart_time = am_pm_split(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<td width=95 align=left style=font:normal 12px Arial, Helvetica, sans-serif;>(.*?)<span/).first.first.gsub(" ", ""))
				  		arrival_time = am_pm_split(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<td width=95 align=left style=font:normal 12px Arial, Helvetica, sans-serif;>(.*?)<span/).last.first.gsub(" ", ""))
				  		#binding.pry
				  		depart_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, depart_time[:hour].to_i, depart_time[:min].to_i, 0, 0)
				  		arrival_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, arrival_time[:hour].to_i, arrival_time[:min].to_i, 0, 0)
			            
			            flight = Flight.where(depart_time: depart_time).first_or_create do |f|
			              f.trip_id = trip.id
			              f.airline_id = airline_id
			              f.depart_airport = depart_airport
			              f.depart_time = depart_time
			              f.arrival_airport = arrival_airport
			              f.arrival_time = arrival_time
			              f.seat_type = "US Airways"
			            end
				  	end
			  	end
			else
		  		matches = dom.xpath('/html/body/div/table/tr[2]/td/table/tr[1]/td/table[7]/tr')
			  	important = matches.map{|match| match unless match.attributes["style"].blank?}.compact
			  	split_points = important.map{|match| match if match.attributes["style"].value == "padding-top: 15px;"}.each_with_index.map{|a, index| index  unless a.nil?}.compact.map{|a| a unless a == 0}.compact
			  	day_array = []
			  	split_points.each_with_index do |split, index|
			  		if split_points.count == 1
			  			day_array << important[0...split]
			  			day_array << important[split...important.count]
			  		elsif index == 0#first iteration if there is more than 1 split point
			  			day_array << important[0...split]
			  		elsif index < split_points.count-1#2nd, 3rd, 4th iterations
			  			day_array << important[split_points[index-1]...split]
			  		else#last split going to end of array
			  			day_array << important.each_slice(split).to_a.last
			  		end
			  	end
			  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
			  	#day_array is array of the flights by day of travel
			  	day_array.each do |day|
			  		flight_count = (day.count-3) #counts the number of flights that day
			  		date_month_day_year = day[1].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\/strong>(.*?)<\/div>/).first.first.strip!.gsub(",", "").split
			  		flight_count_array = [*1..flight_count]
			  		flight_count_array.each_with_index do |value, index|
				  		y = (3)+(index*1)
				  		depart_airport = Airport.find_by_faa(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<span style=color: #227db2;>(.*?)<\/span>/).first.first.split.first).id
				  		arrival_airport = Airport.find_by_faa(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<span style=color: #227db2;>(.*?)<\/span>/).last.first.split.first).id
				  		depart_time = am_pm_split(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/td style=vertical-align: middle; margin: 0px; width: 80px; white-space: nowrap; text-align: center>(.*?)<span/).first.first.gsub(" ", ""))
				  		arrival_time = am_pm_split(day[y].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/td style=vertical-align: middle; margin: 0px; width: 80px; white-space: nowrap; text-align: center>(.*?)<span/).last.first.gsub(" ", ""))
				  		
				  		#binding.pry
				  		depart_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, depart_time[:hour].to_i, depart_time[:min].to_i, 0, 0)#error here
				  		arrival_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, arrival_time[:hour].to_i, arrival_time[:min].to_i, 0, 0)

			            flight = Flight.where(depart_time: depart_time).first_or_create do |f|
			              f.trip_id = trip.id
			              f.airline_id = airline_id
			              f.depart_airport = depart_airport
			              f.depart_time = depart_time
			              f.arrival_airport = arrival_airport
			              f.arrival_time = arrival_time
			              f.seat_type = "US Airways"
			            end
				  	end
			  	end
			end
		end
  	end
  end
  def jetblue
  	user_id = 21
  	user = User.find(user_id)
  	#auth into contextio
  	#contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first
	
	airline_id = Airline.find_by_name("JetBlue").id
	##JETBLUE NEW
  	jb_messages = account.messages.where(from: "reservations@jetblue.com", subject: "Itinerary for your upcoming trip", limit: 500)
  	jb_messages.each do |message|
  		if Trip.find_by_message_id(message.message_id).nil?
	  		year = message.received_at.strftime("%Y")
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		if dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').count > 0
		  		number_of_flights = (dom.xpath('//*[@id="ticket"]/div/table/tr/td/table[4]/tr').count-5)/2
		  		flight_loop = (1..number_of_flights).to_a
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		flight_loop.each_with_index do |flight, index|
		  			flight_index = (index + 1)*2
		  			flight_data = dom.xpath("//*[@id='ticket']/div/table/tr/td/table[4]/tr[#{flight_index}]/td")
		  			day_count = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.count
		  			day = flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-1].to_i
		  			month = month_to_number(flight_data[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split[day_count-2])
		  			d_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.first)
		  			a_time = am_pm_split(flight_data[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split.last)

			  		message_year_check(month, year)
			  		depart_time = DateTime.new(year.to_i, month.to_i, day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)
		  			arrival_time = DateTime.new(year.to_i, month.to_i, day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

			  		airport_cities = flight_data[2].to_s.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/<strong>(.*?)<\/strong>/)
			  		d_city = airport_cities.first.first.split(",").first.titleize
			  		a_city = airport_cities.last.first.split(",").first.titleize
			  		
					begin
		  				depart_airport = Airport.find_by_city(d_city).id
		  				deflightfix = false
		  			rescue Exception => e
		  				de = city_error_check(d_city, 1, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, d_city, airline_id, user_id) if de.airport_id.blank?
		  				depart_airport = de.airport_id.blank? ? 1 : de.airport_id#Random airport
		  				deflightfix = true if de.airport_id.blank? #set flag
			  		end

					begin
		  				arrival_airport = Airport.find_by_city(a_city).id
		  				aeflightfix = false
		  			rescue Exception => e
		  				ae = city_error_check(a_city, 2, airline_id, message.message_id, trip.id)
		  				rollbar_error(message.message_id, a_city, airline_id, user_id) if ae.airport_id.blank?
		  				arrival_airport = ae.airport_id.blank? ? 2 : ae.airport_id#Random airport
		  				aeflightfix = true if ae.airport_id.blank? #set flag
			  		end

		  			
					flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.depart_time = depart_time
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = arrival_time
		  				f.seat_type = "Jetblue"
					end
			  			
			  		FlightFix.create(airline_mapping_id: de.id, flight_id: flight.id, trip_id: trip.id, direction: 1) if deflightfix
			  		FlightFix.create(airline_mapping_id: ae.id, flight_id: flight.id, trip_id: trip.id, direction: 2) if aeflightfix
		  		end
		  	else
		  		matches = dom.xpath('/html/body/table/tr[2]/td[2]/table/tr[9]/td/table/tr[3]/td/table/tr')
		  		matches = matches.select.with_index{|x, i| x unless i < 2} #remove first rows
		  		matches = matches.select.with_index{|x, i| x unless i.odd?} #get everyother row
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		matches.each do |match|
		  			cols = match.xpath('td')
		  			date = cols[0].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split(",").last
		  			day = date.match(/\d+/).to_s
		  			month = month_to_number(date.split(day).first)
		  			time = cols[1].text().gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').strip.split()
		  			depart_hour = am_pm_split(time.first)
		  			arrival_hour = am_pm_split(time.last)
		  			airports = cols[2].text().scan(/\((.*?)\)/)
		  			depart_airport = Airport.find_by_faa(airports.first.first).id
		  			arrival_airport = Airport.find_by_faa(airports.last.first).id

			  		arrival_time = DateTime.new(year.to_i,month.to_i,day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
			  		depart_time = DateTime.new(year.to_i,month.to_i,day.to_i,depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

					flight = Flight.where(depart_time: depart_time).first_or_create do |f|
						f.trip_id = trip.id
						f.airline_id = airline_id
						f.depart_airport = depart_airport
						f.depart_time = depart_time
						f.arrival_airport = arrival_airport
						f.arrival_time = arrival_time
						f.seat_type = "Jetblue"
					end
		  		end
		  	end
	  	end
  	end
  end

  def virgin
  	user = current_user
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	user = User.find(18)
  	user_id = 18
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
  def orbitz
  	#auth into contextio
  	user_id = 18
  	user = User.find(user_id)
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: "trojanette07@yahoo.com").first
  	airline_id = Airline.find_by_name("Orbitz").id
	email_change_date = Date.new(2011,1,1).to_time.to_i
  	o_messages = account.messages.where(from: "travelercare@orbitz.com", subject: "/Prepare For Your Trip/i", limit: 500)
	o_messages.each do |message|
		if Trip.find_by_message_id(message.message_id).nil?
			dom = Nokogiri::HTML(message.body_parts.first.content)
	  		matches = dom.xpath('//*[@id="emailFrame"]/tr/td/table/tr[2]/td[2]/table/tr[2]/td').map(&:to_s)
	  		if matches.count > 0
		  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
		  		matches.each do |match|
				  	match = match.gsub("\t","").gsub("\n","").gsub("\r","")
				  	if match.scan(/<b>(.*?)<\/b>/).count > 0
		  				@year = match.scan(/<b>(.*?)<\/b>/)[2].first.split.last
		  				split_flights = ActionView::Base.full_sanitizer.sanitize(match).split("--------------------------------")
		  				split_flights.each do |flight|
		  					flight = flight.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
			  				departure_data = flight.scan(/Departure(.*?)Arrival/)
		  					if flight.scan(/Arrival(.*?)Seat/).count > 0
			  					arrival_data = flight.scan(/Arrival(.*?)Seat/)
			  					arrival_airport = Airport.find_by_faa(arrival_data.first.first.scan(/\((.*?)\)/).first.first).id
			  					arrival_time = orbitz_time(arrival_data.first.first.scan(/\:(.*?)\(/).first.first)
			  				else
			  					arrival_data = flight.scan(/Arrival(.*?)Class/).first.first.scan(/\:(.*?)\(/).first.first.strip.split
			  					arrival_day = arrival_data[1].split(",").first.to_i
			  					arrival_month = month_to_number(arrival_data[0])
			  					arrival_hour = am_pm_split(arrival_data[2]+arrival_data[3])
			  					arrival_time = DateTime.new(@year.to_i,arrival_month.to_i,arrival_day.to_i,arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)
			  					arrival_airport = Airport.find_by_faa(flight.scan(/Arrival(.*?)Class/).first.first.scan(/\((.*?)\)/).first.first).id
			  				end
			  				depart_airport = Airport.find_by_faa(departure_data.first.first.scan(/\((.*?)\)/).first.first).id
			  				depart_time = orbitz_time(departure_data.first.first.scan(/\:(.*?)\(/).first.first)
			  				#seat_type = arrival_data.first.first.scan(/Class:(.*)/).first.first

							flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
			  					f.trip_id = trip.id
			  					f.airline_id = airline_id
			  					f.depart_airport = depart_airport
			  					f.depart_time = depart_time
			  					f.arrival_airport = arrival_airport
			  					f.arrival_time = arrival_time
			  					f.seat_type = "Orbitz"
							end
		  				end
		  			end
		  		end
		  	else
				matches = dom.xpath('/html/body/table/tr/td/table[2]/tr/td[1]/div[1]/table[2]/tr[2]/td/table/tr/td/table/tr').map(&:to_s)
			  	year_array = dom.xpath('/html/body/table/tr/td/table[2]/tr/td[2]/div[1]/table[1]/tr[3]/td/div[3]/text()')
			  	year = year_array.to_s.split[8]
			  	flight_arrays = matches.each_slice(7).to_a
			  	flight_arrays.pop
			  	trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
			  	flight_arrays.each do |flight|
			  		
			  		#flight data
			  		flight_date_split = ActionView::Base.full_sanitizer.sanitize(flight[0]).split
			  		word_count = flight_date_split.count
			  		if word_count == 9
				  		month = flight_date_split[3]
				  		day = flight_date_split[4]
				  	else
				  		month = flight_date_split[2]
				  		day = flight_date_split[3]
				  	end

			  		#departure data
			  		depart_array_extra = ActionView::Base.full_sanitizer.sanitize(flight[2])
			  		depart_array_extra = depart_array_extra.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
			  		depart_array = depart_array_extra.scan(/(^.*?)\|/)
			  		depart_array = depart_array.first.first
			  		depart_array = depart_array.split
			  		depart_time = "#{depart_array[0]} #{depart_array[1]}"
			  		depart_array.shift(2)
			  		depart_airport = depart_array
			  		depart_airport = depart_airport.join(" ")
			  		depart_airport = Airport.find_by_faa(depart_airport.scan(/\((.*?)\)/).first.first).id
			  		airport_data = flight[1]
			  		airport_data = airport_data.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
			  		airline_array = airport_data.scan(/<span class="flightNameAndNumber">(.*?)<\/span>/).first.first.split
			  		airline_array.pop
			  		airline = airline_array.join(" ")
			  		depart_time = create_saveable_date(day, month, year, depart_time)

			  		#arrival data
			  		arrival_array_extra = ActionView::Base.full_sanitizer.sanitize(flight[4])
			  		arrival_array_extra = arrival_array_extra.gsub("\t","").gsub("\n","").gsub("\r","").gsub("&nbsp;","")
			  		arrival_array = arrival_array_extra.scan(/(^.*?)\|/)
			  		arrival_array = arrival_array.first.first
			  		arrival_array = arrival_array.split
			  		arrival_time = "#{arrival_array[0]} #{arrival_array[1]}"
			  		arrival_array.shift(2)
			  		arrival_airport = arrival_array
			  		arrival_airport = arrival_airport.join(" ")
			  		arrival_airport = Airport.find_by_faa(arrival_airport.scan(/\((.*?)\)/).first.first).id
			  		arrival_time = create_saveable_date(day, month, year, arrival_time)
					
					flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
		  				f.trip_id = trip.id
		  				f.airline_id = airline_id
		  				f.depart_airport = depart_airport
		  				f.depart_time = depart_time
		  				f.arrival_airport = arrival_airport
		  				f.arrival_time = arrival_time
		  				f.seat_type = "Orbitz"
					end
			  	end
			end	
	  	end
	end
  end

  def united
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: current_user.email).first
  	
  	email_change_date = Date.new(2011,1,1).to_time.to_i


  	u_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_before: email_change_date)
	
	if u_messages.count > 0
		#u_messages = u_messages.map {|message| message.body_parts.first.content}

		u_messages.each do |message|
			trip = Trip.find_or_create_by_name_and_message_id(user_id: current_user.id, message_id: message.message_id)
			dom = Nokogiri::HTML(message.body_parts.first.content)
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
			  		Flight.find_or_create_by_depart_time(trip_id: trip.id, airline_id: 41, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: depart_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: arrival_time, seat_type: seat_type )
				
			end
		end
	end
  	

  	##OLD UNITED
  	u_oldest_messages = account.messages.where(from: "UNITED-CONFIRMATION@united.com", subject: '/Your United flight confirmation -/', date_after: email_change_date)
  	if u_oldest_messages.count > 0 
	  	#u_oldest_messages = u_oldest_messages.map {|message| message.body_parts.first.content}
	  	u_oldest_messages.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
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

		  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 41, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: depart_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: arrival_time, seat_type: seat_type )
	  			end
	  		end
	  	end
	end
  end

  def cheapo
  	user_id = 18
  	user = User.find(user_id)
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: "carly.creighton@gmail.com").first
	c_messages = account.messages.where(from: "cheapoair@cheapoair.com", limit: 500)
	c_messages.each do |message|
		if Trip.find_by_message_id(message.message_id).nil?
			dom = Nokogiri::HTML(message.body_parts.first.content)
			year_data = dom.xpath('//*[@id="FlightBookingDetails"]/td/table[4]/tr/td/table/tr[1]')
			if year_data.count > 0
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
			else
				#
			end
		end#No other trips 
	end
  end

  def import
  	#csv_path = Rails.root.join("public", "airports.csv")
  	#Airport.import(File.read(csv_path))
    #redirect_to root_url, notice: "Products imported."
  end


  def priceline
  	user = current_user

  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	

  	#get messages from Virgin and pick the html
  	pl_messages = account.messages.where(from: "ItineraryAir@trans.priceline.com", subject: "/Your Itinerary for/")
  	pl_messages.each do |message|
  		email = message.body_parts.first.content
  		trip = Trip.create(user_id: user.id, name: "Priceline test")
  		
  		dom = Nokogiri::HTML(email)
  		flight_dates = dom.xpath('//td[@colspan="3"]').each_slice(3).to_a
  		arrival_data = dom.xpath('//td[@style="padding:5px;border:1px solid #0A84C1;"]').each_slice(2).to_a
  		depart_data = dom.xpath('//td[@style="padding:5px;border:1px solid #0A84C1;border-right:0;"]').each_slice(4).to_a
  		
  		depart_data.each_with_index do |flight, index|
  			arrival_index = index * 2
  			date_index = index * 3
  			d_data = flight_dates[index][date_index+1]
			a_data = flight_dates[index][date_index+2]
  			
  			airline_name = flight[0].to_s.scan(/>(.*?)<br>/).first.first
  			depart_airport = Airport.find_by_faa(flight[1].to_s.scan(/<b>(.*?)<\/b>/).first.first).id
  			depart_time = am_pm_split(flight[1].to_s.scan(/<b>(.*?)<\/b>/).last.first)
  			arrival_airport = Airport.find_by_faa(arrival_data[index][arrival_index].to_s.scan(/<b>(.*?)<\/b>/).first.first).id
  			arrival_time = am_pm_split(arrival_data[index][arrival_index].to_s.scan(/<b>(.*?)<\/b>/).last.first)
  			
  			d_year = d_data.to_s.scan(/\/b>,(.*?)<\/td>/).first.first.split.last.to_i
  			d_airport = Airport.find_by_faa(d_data.to_s.scan(/<b>(.*?)<\/b>/).first.first).id
  			d_hour_min = am_pm_split(d_data.to_s.scan(/<b>(.*?)<\/b>/)[1].first)
  			d_day = d_data.to_s.scan(/<b>(.*?)<\/b>/)[2].first.split.last.to_i
  			d_month = month_to_number(d_data.to_s.scan(/<b>(.*?)<\/b>/)[2].first.split.first.split(",").last)
			
			a_year = a_data.to_s.scan(/\/b>,(.*?)<\/td>/).first.first.split.last.to_i
  			a_airport = Airport.find_by_faa(a_data.to_s.scan(/<b>(.*?)<\/b>/).first.first).id
  			a_hour_min = am_pm_split(a_data.to_s.scan(/<b>(.*?)<\/b>/)[1].first)
  			a_day = a_data.to_s.scan(/<b>(.*?)<\/b>/)[2].first.split.last.to_i
  			a_month = month_to_number(a_data.to_s.scan(/<b>(.*?)<\/b>/)[2].first.split.first.split(",").last)

  			d_time = DateTime.new(d_year.to_i, d_month.to_i, d_day.to_i, d_hour_min[:hour].to_i, d_hour_min[:min].to_i, 0, 0)
  			a_time = DateTime.new(a_year.to_i, a_month.to_i, a_day.to_i, a_hour_min[:hour].to_i, a_hour_min[:min].to_i, 0, 0)

  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 191, depart_airport: d_airport, depart_time: d_time, arrival_airport: a_airport, arrival_time: a_time, seat_type: "priceline" )

  		end
  	end
  end

  def taca
  	#auth into contextio
  	#contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	user = current_user

  	#get the correct account
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	account = contextio.accounts.where(email: current_user.email).first
  	

  	#get messages from Virgin and pick the html
  	taca_messages = account.messages.where(from: "edesk@taca.com", subject: "/TACA.COM/")
  	if taca_messages.count > 0
	  	taca_messages.each do |message|
	  		#trip = Trip.create(user_id: current_user.id, name: "taca", message_id: message.message_id)
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "Taca")
	  		
	  		email = message.body_parts.first.content.gsub("\r","").gsub("\n","")
	  		
	  		airfare = email.scan(/USD (.*?)<BR>/)
	  		
	  		depart_times = email.scan(/Depart:(.*?)To:/)
	  		
	  		depart_times.each_with_index do |value, index|
	  			depart_time = am_pm_split(email.scan(/Depart:(.*?)To:/)[index].first.gsub(" ",""))
	  			depart_airport = email.scan(/From:(.*?)Depart:/)[index].first.scan(/\((.*?)\)/).first.first
	  			arrival_airport = email.scan(/To:(.*?)Arrive:/)[index].first.scan(/\((.*?)\)/).first.first
	  			arrival_time = am_pm_split(email.scan(/Arrive:(.*?)Flight:/)[index].first.gsub(" ", ""))
	  			day_month_year = email.scan(/Date:(.*?)From:/)[index].first.split

	  			d_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,depart_time[:hour].to_i,depart_time[:min].to_i, 0, 0)
	  			a_time = DateTime.new(day_month_year[2].to_i,month_to_number(day_month_year[1]).to_i,day_month_year[0].to_i,arrival_time[:hour].to_i,arrival_time[:min].to_i, 0, 0)

	  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 191, depart_airport: Airport.find_by_faa(depart_airport).id, depart_time: d_time, arrival_airport: Airport.find_by_faa(arrival_airport).id, arrival_time: a_time, seat_type: "taca" )
	  		end
	  	end
	end  		
  end
  	
  def flighthub
  	user = current_user
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: "blgruber@gmail.com").first


  	flighthub_messages = account.messages.where(from: "noreply@flighthub.com", subject: "/Your Electronic Ticket/")
  	if flighthub_messages.count > 0 
	  	#flighthub_messages = flighthub_messages.map {|message| message.body_parts.where(type: 'text/html').first.content}
	  	flighthub_messages.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)

	  		dom = Nokogiri::HTML(message.body_parts.where(type: 'text/html').first.content)
	  		matches = dom.xpath('/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr').map(&:to_s)
	  		flights = matches.each_slice(2).map(&:last)
	  		flights.each_with_index do |flight, index|
	  			x = (index+1)*2
	  			airports = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[1]/td[1]/text()").to_s.split
	  			times = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[1]/td[3]/text()").to_s.split
	  			d_time = DateTime.new(times[2].to_i,month_to_number(times[1]),times[0].to_i,times[3].split(":")[0].to_i,times[3].split(":")[1].to_i, 0, 0)
	  			a_time = DateTime.new(times[6].to_i,month_to_number(times[5]),times[4].to_i,times[7].split(":")[0].to_i,times[7].split(":")[1].to_i, 0, 0)
	  			airline = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[2]/td/text()").to_s.split.first
	  			

	  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 23, depart_airport: Airport.find_by_faa(airports[0]).id, depart_time: d_time, arrival_airport: Airport.find_by_faa(airports[1]).id, arrival_time: a_time, seat_type: airline )

	  		end 
		end
	end
  end

  def northwest
  	user = current_user
  	#auth into contextio
  	#contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	

  	#get the correct account
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	account = contextio.accounts.where(email: current_user.email).first
  	
  	airline_id = Airline.find_by_name("Northwest Airlines").id
  	#get messages from Virgin and pick the html
  	nw_messages = account.messages.where(from: "Northwest.Airlines@nwa.com", subject: "/nwa.com Reservations Air Purchase Confirmation/")
  	if nw_messages.count > 0
	  	nw_messages.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "NorthWest")
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		year = message.received_at.strftime("%Y")
	  		cost = dom.xpath('//*[@id="totalCost"]').to_s.scan(/Price:(.*?)</).first.first.gsub(" ", "")
	  		legdata = dom.xpath('/html/body/div[@class="legdata"]')
	  		flights_array = legdata.each_slice(5).to_a
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

	  			user.flights.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: airline_id, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "Northwest" )
	  		end

	  	end
	end
  end
  def southwest
  	user = current_user
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	

  	#get the correct account
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	account = contextio.accounts.where(email: current_user.email).first
  	
  	airline_id = Airline.find_by_name("Southwest Airlines").id
  	#get messages from Virgin and pick the html
  	sw_messages = account.messages.where(from: "SouthwestAirlines@luv.southwest.com", subject: "/Southwest Airlines Confirmation-/")
  	if sw_messages.count > 0
	  	sw_messages.each do |message|
	  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "SouthWest")
	  		year = message.received_at.strftime("%Y")
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  		#cost = dom.xpath('//div[@style="line-height: 14px; font-family: arial,verdana; color: #666666; font-size: 11px; margin-right: 18px"]')#need to check further
	  		flights_array = dom.xpath('//div[@style="line-height: 14px; font-family: arial,verdana; color: #000000; font-size: 11px"]').map(&:to_s).each_slice(3).to_a
	  		flights_array.each do |flight|
	  			unless flight.count < 3
		  			flight_date = flight[0].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/>(.*?)</).first.first.split
		  			month = month_to_number(flight_date[1])
		  			day = flight_date[2]
		  			depart_airport = Airport.find_by_faa(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).first.first).id
		  			arrival_airport = Airport.find_by_faa(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/\((.*?)\)/).last.first).id
		  			d_time = am_pm_split(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/b>(.*?)<\/b/)[1].first)
		  			a_time = am_pm_split(flight[2].gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '').scan(/b>(.*?)<\/b/)[3].first)
		  			year = message_year_check(month, year)
		  			depart_time = DateTime.new(year.to_i, month.to_i, day.to_i, d_time[:hour].to_i, d_time[:min].to_i, 0, 0)
		  			arrival_time = DateTime.new(year.to_i, month.to_i, day.to_i, a_time[:hour].to_i, a_time[:min].to_i, 0, 0)

		  			Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: airline_id, depart_airport: depart_airport, depart_time: depart_time, arrival_airport: arrival_airport, arrival_time: arrival_time, seat_type: "Southwest" )
		  		end
	  		end
	  	end
	end
  end
  
  def hotwire
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	account = contextio.accounts.where(email: "chris.r.crittenden@gmail.com").first
  	
  	user = User.find(18)
  	airline_id = Airline.find_by_name("Hotwire").id
  	#get messages from Virgin and pick the html
  	sw_messages = account.messages.where(from: "support@hotwire.com", subject: "/Hotwire Flight Purchase Confirmation/")
  	sw_messages.each do |message|
  		email = message.body_parts.first.content.gsub("\r", "").gsub("\n", "").gsub("\t","").gsub(%r{\"}, '')
  		depart_data = email.scan(/Departs:(.*?)Arrives:/)
  		arrival_data = email.scan(/Arrives:(.*?)Duration:/)
  		trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id, name: "Hotwire")
  		depart_data.each_with_index do |x, i|
  			depart = depart_data[i].first
  			depart_airport = Airport.find_by_faa(depart.scan(/\((.*?)\)/).first.first).id
  			depart_hour = am_pm_split(depart.scan(/at (.+)/).first.first)
  			depart_month_day_year = depart.scan(/\)(.*?) at/).first.first.split(",")
  			depart_year = depart_month_day_year[2]
  			depart_month = month_to_number(depart_month_day_year[1].split[0])
  			depart_day = depart_month_day_year[1].split[1].to_i

  			depart_time = DateTime.new(depart_year.to_i, depart_month.to_i, depart_day.to_i, depart_hour[:hour].to_i,depart_hour[:min].to_i, 0, 0)

			arrival = arrival_data[i].first
  			arrival_airport = Airport.find_by_faa(arrival.scan(/\((.*?)\)/).first.first).id
  			arrival_hour = am_pm_split(arrival.scan(/\) (.*?) on/).first.first)
  			arrival_month_day_year = arrival.scan(/on (.+)/).first.first.split(",")
  			arrival_year = arrival_month_day_year[2]
  			arrival_month = month_to_number(arrival_month_day_year[1].split[0])
  			arrival_day = arrival_month_day_year[1].split[1].to_i

  			arrival_time = DateTime.new(arrival_year.to_i, arrival_month.to_i, arrival_day.to_i, arrival_hour[:hour].to_i,arrival_hour[:min].to_i, 0, 0)

            flight = user.flights.where(depart_time: depart_time).first_or_create do |f|
              f.trip_id = trip.id
              f.airline_id = airline_id
              f.depart_airport = depart_airport
              f.depart_time = depart_time
              f.arrival_airport = arrival_airport
              f.arrival_time = arrival_time
              f.seat_type = "Hotwire"
            end

  		end
  	end
  end

  def emirates
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	user = User.find(18)
  	account = contextio.accounts.where(email: user.email).first
  	
  	
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
  end

  def easyjet
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#account = contextio.accounts.where(email: "blgruber@gmail.com").first
  	user = User.find(18)
  	user_id = 18
  	account = contextio.accounts.where(email: "annievenezia@gmail.com").first
  	
  	
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

  def travelocity
  	contextio = ContextIO.new('h00j8lpl', 'ueWLBkDRE6xlg2am')
  	user = User.find(18)
  	user_id = 18
  	account = contextio.accounts.where(email: "nshemesh12@gmail.com").first
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

  private
  def year_to_four(two)
  	if two < 20
  		return "19#{two}"
  	else
  		return "20#{two}"
  	end
  end

  def gmaps4rails_infowindow
	  # add here whatever html content you desire, it will be displayed when users clicks on the marker
  end
  def get_first_number(full_string)
  	return full_string.match(/\d+/).to_s
  end

  def get_string_from_number_split(full_string, number)
  	return full_string.split(number)[1]
  end

  def split_by_space(full_string)
  	return full_string.strip.split(/\s+/)
  end

  def am_pm_split(full_time)
  	if full_time.scan(/a.m./i).count > 0
  		reg_time = full_time.split(/a.m./i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	elsif full_time.scan(/p.m./i).count > 0
  		reg_time = full_time.split(/p.m./i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  		hour = hour + 12 unless hour == 12
  	elsif full_time.scan(/pm/i).count > 0
  		reg_time = full_time.split(/pm/i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  		hour = hour + 12 unless hour == 12
  	elsif full_time.scan(/am/i).count > 0
  		reg_time = full_time.split(/am/i).first
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	elsif full_time.scan(/P/i).count > 0
  		reg_time = full_time.split("P").first
  		if reg_time.length == 3
  			hour = reg_time.first.to_i
  			hour_min = [0, reg_time[1]+reg_time[2] ]
  		else
  			hour = (reg_time[0]+reg_time[1]).to_i
  			hour_min = [0, reg_time[2]+reg_time[3]]
  		end
  		hour = hour + 12 unless hour == 12
  	elsif full_time.scan(/A/i).count > 0
  		reg_time = full_time.split("A").first
  		if reg_time.length == 3
  			hour = reg_time.first.to_i
  			hour_min = [0, reg_time[1]+reg_time[2] ]
  		else
  			hour = (reg_time[0]+reg_time[1]).to_i
  			hour_min = [0, reg_time[2]+reg_time[3]]
  		end
	elsif full_time.scan(/N/i).count > 0
		hour = 12
		hour_min = [0, "00"]
  	else
  		reg_time = full_time
  		hour_min = reg_time.split(":")
  		hour = hour_min[0].to_i
  	end
  	min = hour_min[1]
  	return {hour: hour, min: min}
  end

  def create_saveable_date(day, month, year, hour)
  	if month.class != Fixnum
	  	if month.length < 4
	  		num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
	  	else
	  		num_month = month
	  	end
	else
		num_month = month
	end
  	new_date = Time.parse("#{year}-#{num_month}-#{day} #{hour}")
  	#string_date = "#{day}/#{num_month}/#{year} #{hour}"
  	#real_date = Chronic.parse(string_date)
  	return new_date
  end
  
  def flight_date_time(day, monthy, year, hour, min)
	month = month_to_number(monthy)
	year_new = year.gsub(/\W+/, '')
	flight_date = DateTime.new(year_new.to_i,month_to_number.to_i,day.to_i,hour.to_i,min.to_i, 0, 0)
	
	return flight_date
  end

  def month_to_number(month)
  	if month.class != Fixnum
	  	month = month.gsub(/\W+/, '')
	  	if month.length < 4
	  		num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
	  	else
	  		num_month = Date::MONTHNAMES.index(month)
	  	end
	else
		num_month = month
	end
	return num_month
  end

  def orbitz_time(string_date)
  	month_name = string_date.split[0]
  	month = Date::MONTHNAMES.index("#{month_name}")
  	day = string_date.split[1]
  	hour = "#{string_date.split[2]} #{string_date[3]}"
  	create_saveable_date(day, month, @year, hour)
  end

  def old_jb_time(date,time)
  	string_date = "#{date} #{time}"
  	return Chronic.parse(string_date)
  end

  def find_destination(trip)
    if trip.flights.count < 3
    	return Airport.find(trip.flights.first.arrival_airport)
    elsif trip.flights.count.even?
    	x = (trip.flights.count/2)-1
    	middle = trip.flights[x]
    	return Airport.find(middle.arrival_airport)
    else
    	x = (trip.flights.count/2)-0.5
    	middle = trip.flights[x]
    	return Airport.find(middle.arrival_airport)
    end
  end
  def jb_city_airport(jb_city)
    if jb_city == "New York Jfk" || jb_city == "New York Lga"
      airport_nyc = jb_city.split(" ").last.upcase
      return  Airport.find_by_faa(airport_nyc).id
    elsif jb_city == "Portland Or"
      return Airport.where("city = ?", "Portland").first.id
    elsif jb_city == "Ft Lauderdale"
      return Airport.find_by_city("Fort Lauderdale").id
    else
      if Airport.where("city = ?", jb_city).count > 0
        return Airport.where("city = ?", jb_city).first.id
      else 
        return 1
      end
    end
  end

  def message_year_check(month, year)
    if month == "12"
      return year.to_i
    else
      return year.to_i + 1
    end
  end
  	def destination_flight_number(trip)
    	if trip.flights.count < 3 #if the trip has 1 or 2 flights
        	return 0
        elsif trip.flights.count.even? #if the trip has 3 or more flights and is even its probably the middle one
        	return (trip.flights.count/2)-1
        else#if the trip has 3 or more flights and is odd its probably the first of the middle ones
        	return (trip.flights.count/2)-0.5
        end
	end
  def message_year_check(month, year)
    if month == "12"
      return year.to_i
    else
      return year.to_i + 1
    end
  end

  def city_error_check(city, direction, airline_id, message_id, trip)
    return AirportMapping.where(city: city).first_or_create do |am| 
      am.airline_id = airline_id
      am.note = direction
      am.message_id = message_id
      am.trip_id = trip
    end
  end
  
  def rollbar_error(message_id, city, airline_id, user_id)
    #Rollbar.report_exception(e, rollbar_request_data, rollbar_person_data)
    #Rollbar.report_message("Bad City", "error", :message_id => message_id, :city => city)
    ErrorMailer.uca(user_id, city, message_id, airline_id ).deliver
  end

end
