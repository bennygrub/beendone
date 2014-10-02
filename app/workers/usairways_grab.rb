require 'res_helper'
require 'resque-retry'
class UsairwaysGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :usairways_queue
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

  	email_change_date = Date.new(2014,1,1).to_time.to_i

  	a_id = Airline.where("name = ?", "USAir").first.id

  	usa_messages = account.messages.where(from: "reservations@email-usairways.com", date_before: email_change_date)
  	usa_messages.each do |message|
	  	trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)
  		dom = Nokogiri::HTML(message.body_parts.first.content)
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
		  		d_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, depart_time[:hour].to_i, depart_time[:min].to_i, 0, 0)
		  		a_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, arrival_time[:hour].to_i, arrival_time[:min].to_i, 0, 0)

		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: a_id, depart_airport: depart_airport, depart_time: d_time, arrival_airport: arrival_airport, arrival_time: a_time, seat_type: "US Airways Before 2014" )
		  	end

	  	end
  	end
  	#US AIRWAYS NEW EMAIL STARTING 2014
  	#get messages from delta and pick the html
  	usa_messages = account.messages.where(from: "reservations@email-usairways.com", date_after: email_change_date)
  	usa_messages.each do |message|
	  	trip = Trip.find_or_create_by_message_id(user_id: user.id, message_id: message.message_id)
  		dom = Nokogiri::HTML(message.body_parts.first.content)
	  	matches = dom.xpath('/html/body/div/table/tr[2]/td/table/tr[1]/td/table[5]/tr')
	  	important = matches.map{|match| match unless match.attributes["style"].blank?}.compact
	  	split_points = important.map{|match| match if match.attributes["style"].value == "padding-top:17px;"}.each_with_index.map{|a, index| index  unless a.nil?}.compact.map{|a| a unless a == 0}.compact
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
		  		d_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, depart_time[:hour].to_i, depart_time[:min].to_i, 0, 0)
		  		a_time = DateTime.new(date_month_day_year[3].to_i, month_to_number(date_month_day_year[1]).to_i, date_month_day_year[2].to_i, arrival_time[:hour].to_i, arrival_time[:min].to_i, 0, 0)

		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: a_id, depart_airport: depart_airport, depart_time: d_time, arrival_airport: arrival_airport, arrival_time: a_time, seat_type: "US Airways 2014" )
		  	end

	  	end
  	end
  end
end