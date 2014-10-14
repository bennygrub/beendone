require 'res_helper'
require 'resque-retry'
class PricelineGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status

  @queue = :priceline_queue
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


  	pl_messages = account.messages.where(from: "ItineraryAir@trans.priceline.com", subject: "/Your Itinerary for/")
  	pl_messages.each do |message|
  		email = message.body_parts.first.content
  		
  		dom = Nokogiri::HTML(email)
  		flight_dates = dom.xpath('//td[@colspan="3"]').each_slice(3).to_a
  		arrival_data = dom.xpath('//td[@style="padding:5px;border:1px solid #0A84C1;"]').each_slice(2).to_a
  		depart_data = dom.xpath('//td[@style="padding:5px;border:1px solid #0A84C1;border-right:0;"]').each_slice(4).to_a
  		trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
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
        
        flight = Flight.where(trip_id: trip.id, depart_time: d_time.to_time).first_or_create do |f|
            f.trip_id = trip.id
            f.airline_id = 191
            f.depart_airport = depart_airport
            f.arrival_airport = arrival_airport
            f.arrival_time = a_time
            f.seat_type = "Priceline"
        end
  		end
  	end
  end
end