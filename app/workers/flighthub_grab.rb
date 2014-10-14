require 'res_helper'
require 'resque-retry'
class FlighthubGrab
  extend ResHelper
  extend Resque::Plugins::Retry
  include Resque::Plugins::Status
  @queue = :flighthub_queue
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


  	flighthub_messages = account.messages.where(from: "noreply@flighthub.com", subject: "/Your Electronic Ticket/")
  	flighthub_messages.each do |message|
  		dom = Nokogiri::HTML(message.body_parts.where(type: 'text/html').first.content)
  		matches = dom.xpath('/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr').map(&:to_s)
  		flights = matches.each_slice(2).map(&:last)
      trip = Trip.where(user_id: user.id, message_id: message.message_id).first_or_create
  		flights.each_with_index do |flight, index|
  			x = (index+1)*2
  			airports = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[1]/td[1]/text()").to_s.split
  			times = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[1]/td[3]/text()").to_s.split
  			d_time = DateTime.new(times[2].to_i,month_to_number(times[1]),times[0].to_i,times[3].split(":")[0].to_i,times[3].split(":")[1].to_i, 0, 0)
  			a_time = DateTime.new(times[6].to_i,month_to_number(times[5]),times[4].to_i,times[7].split(":")[0].to_i,times[7].split(":")[1].to_i, 0, 0)
  			airline = dom.xpath("/html/body/table/tr/td/table[3]/tr/td/table[3]/tr[2]/td[2]/table/tr[#{x}]/td/table/tr[2]/td/text()").to_s.split.first
  			depart_airport = Airport.find_by_faa(airports[0]).id
        arrival_airport = Airport.find_by_faa(airports[1]).id

        flight = Flight.where(trip_id: trip.id, depart_time: d_time.to_time).first_or_create do |f|
            f.trip_id = trip.id
            f.airline_id = 23
            f.depart_airport = depart_airport
            f.arrival_airport = arrival_airport
            f.arrival_time = a_time
            f.seat_type = airline
        end
  		end
    end 
  end
end