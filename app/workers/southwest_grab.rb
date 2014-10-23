require 'res_helper'
require 'resque-retry'
class SouthwestGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  include ResHelper

  @queue = :southwest_queue
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


  	airline_id = Airline.find_by_name("Southwest Airlines").id
  	#get messages from Virgin and pick the html
    sw_messages = account.messages.where(from: "SouthwestAirlines@luv.southwest.com", subject: "/Southwest Airlines Confirmation-/")
    sw_messages.each do |message|
      if Trip.find_by_message_id(message.message_id).nil?
        year = message.received_at.strftime("%Y")
        dom = Nokogiri::HTML(message.body_parts.first.content)
        #cost = dom.xpath('//div[@style="line-height: 14px; font-family: arial,verdana; color: #666666; font-size: 11px; margin-right: 18px"]')#need to check further
        flights_array = dom.xpath('//div[@style="line-height: 14px; font-family: arial,verdana; color: #000000; font-size: 11px"]').map(&:to_s).each_slice(3).to_a
        trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
        
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
            
            flight = Flight.where(depart_time: depart_time).first_or_create do |f|
              f.trip_id = trip.id
              f.airline_id = airline_id
              f.depart_airport = depart_airport
              f.depart_time = depart_time
              f.arrival_airport = arrival_airport
              f.arrival_time = arrival_time
              f.seat_type = "Southwest"
            end
          end
        end
      end
    end
  end
end