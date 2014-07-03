class PagesController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'chronic'

  def home
  end

  def about
  	#auth into contextio
  	contextio = ContextIO.new('p3o3c7vm', '8kYkj7Qv9xKeVitj')
  	#get the correct account
  	account = contextio.accounts.where(email: 'blgruber@gmail.com').first
  	
  	#get messages from delta and pick the html
  	delta_messages = account.messages.where(from: "deltaelectronicticketreceipt@delta.com", subject: "BEN G - NYC-KENNEDY 13JUN11")
  	delta_messages = delta_messages.map {|message| message.body_parts.first.content}


  	delta_messages.each do |message_string|
	  	dom = Nokogiri::HTML(message_string)
	  	matches = dom.xpath('/html/body//pre/text()').map(&:to_s)

	  	#flight_count = matches[0].scan(/(^.*?)LV/).count
	  	
	  	#departure information
	  	departure_date_data = matches[0].scan(/(^.*?)LV/).first.first.strip.split(/\s+/)
	  	
	  	departure_day_of_week = departure_date_data[0]
	  	departure_day_of_month = departure_date_data[1].match(/\d+/)
	  	departure_month = departure_date_data[1].split("#{departure_day_of_month}")[1]
	  	departure_time_data = matches[0].match(/\LV(.*)/).to_s.strip.split(/\s+/)
	  	departure_airport = departure_time_data[1]
	  	departure_hour = departure_time_data[2].match(/\d+/)
	  	departure_hour_seg = departure_time_data[2].split("#{departure_hour}")[1]



	  	#arrival information
	  	#arrival_data = matches[0].match(/AR (.*)/).to_s.strip.split(/\s+/)
	  	matches[0].scan(/AR (.*)/).each do |arrival|
	  		raise "#{arrival}"
	  		arrival_airport = arrival_data[1]
	  		arrival_hour = get_first_number(arrival_data[2])
	  		arrival_hour_seg = get_string_from_number_split(arrival_data[2].to_s, arrival_hour)
	  	end
	  	#get airfare
	  	fare = matches[2].scan(/Fare: (.+)/).first.first.strip.split(/\s+/).first
	  	seat_type = arrival_data[3]
	  	issue_data = matches.last.match(/Issue date:(.*)/).to_s
	  	issue_date = split_by_space(issue_data)[2]
	  	issue_year = issue_date.split(//).last(2).join("").to_i

	  	departure_full_date_time = create_saveable_date(departure_day_of_month,departure_month,issue_year, departure_time_data[2] )
	  	arrival_full_date_time = create_saveable_date(departure_day_of_month,departure_month,issue_year, arrival_data[2] )

	  	Flight.create(trip_id: 14, airline_id: 12, depart_airport: departure_airport, depart_time: departure_full_date_time, arrival_airport: arrival_airport, arrival_time: arrival_full_date_time, seat_type: seat_type )
	end
  end

  def contact
  	#matches = ""
  end

  private

  def get_first_number(full_string)
  	return full_string.match(/\d+/).to_s
  end

  def get_string_from_number_split(full_string, number)
  	return full_string.split(number)[1]
  end

  def split_by_space(full_string)
  	return full_string.strip.split(/\s+/)
  end

  def create_saveable_date(day, month, year, hour)
  	num_month = Date::ABBR_MONTHNAMES.index(month.capitalize)
  	string_date = "#{day}/#{num_month}/#{year} #{hour}"
  	real_date = Chronic.parse(string_date)
  	return real_date
  end
end
