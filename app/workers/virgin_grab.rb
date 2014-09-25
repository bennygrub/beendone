require 'res_helper'
require 'resque-retry'
class VirginGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :virgin_queue
  @retry_limit = 5
  @retry_delay = 30

  def self.perform(job_id, user_id)
  	user = User.find(user_id)
  	#auth into contextio
  	contextio = ContextIO.new('d67xxta6', 'AtuL8ONalrRJpQC0')
  	#get the correct account
  	account = contextio.accounts.where(email: user.email).first


  	va_messages = account.messages.where(from: "virginamerica@elevate.virginamerica.com", subject: "/Virgin America Reservation/")
	if va_messages.count > 0 
		#va_messages = va_messages.map {|message| message.body_parts.first.content}
	  	va_messages.each do |message|
	  		trip = Trip.find_or_create_by_name_and_user_id(user_id: user.id, message_id: message.message_id)
	  		dom = Nokogiri::HTML(message.body_parts.first.content)
		  	matches = dom.xpath('/html/body/table/tr[14]/td/table/tr[2]/td/table/tr').map(&:to_s)
		  	matches.shift
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
		  		d_time = Time.parse("#{date} #{both_times[0].first}")
		  		a_time = Time.parse("#{date} #{both_times[1].first}")
		  		Flight.find_or_create_by_depart_time_and_trip_id(trip_id: trip.id, airline_id: 23, depart_airport: Airport.find_by_faa(both_airports[0].first).id, depart_time: d_time, arrival_airport: Airport.find_by_faa(both_airports[1].first).id, arrival_time: a_time, seat_type: "COACH" )
		  	end	
	  	end
	end
  end
end