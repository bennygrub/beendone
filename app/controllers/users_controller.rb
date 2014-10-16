class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  include ApplicationHelper

  def edit
  end

  def show
    @map_page = true
  	@trips = current_user.trips#all trips from current_user
  	@trips = @trips.map{|trip| trip unless trip.flights.count < 1}.compact #get rid of trips with zero flights
  	@trips = @trips.sort_by{|trip| trip.flights.last.depart_time}.reverse #reverse cron from depart_time
  	@trips_by_month = @trips.group_by { |trip| trip.flights.first.depart_time.strftime("%Y") } #organize trips by month
  	
    @destinations_cities = @trips.map{|trip|find_destination(trip).city}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
  	@origins = @trips.map{|trip| Airport.find(trip.flights.first.depart_airport).city}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
    @destination_countries = @trips.map{|trip|find_destination(trip).country}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }

  	@by_month = @trips.map{|trip| trip.flights.first.depart_time.strftime("%B")}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
  	@by_year = @trips.map{|trip| trip.flights.first.depart_time.year}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
  	@by_day_of_week_leave = @trips.map{|trip| trip.flights.first.depart_time.strftime("%A")}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
  	@by_day_of_week_return = @trips.map{|trip| trip.flights.last.depart_time.strftime("%A")}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }
    @airlines = current_user.flights.map{|flight| Airline.find(flight.airline_id).name}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }


  	@flights = current_user.flights
  	@departs = @flights.map{|flight|
  		d_port = Airport.find(flight.depart_airport)
  		OpenStruct.new(
 			{
  				latitude: d_port.latitude, 
  				longitude: d_port.longitude, 
  				a_id: d_port.id,
  				name: d_port.name,
 				city: d_port.city,
  				flight_id: flight.id,
  				trip_id: flight.trip_id,
  				type: "depart"
  			}
  		)
  	}
  	@arrivals = @flights.map{|flight|
  		port = Airport.find(flight.arrival_airport)
  		OpenStruct.new(
  			{
 				latitude: port.latitude, 
  				longitude: port.longitude, 
  				a_id: port.id,
  				name: port.name,
  				flight_id: flight.id,
  				trip_id: flight.trip_id,
  				type: "arrive"
  			}
  		)
  	}
  	@all_flights = @arrivals + @departs
  	@hash = Gmaps4rails.build_markers(@all_flights) do |flight, marker|
  		marker.lat flight.latitude
  		marker.lng flight.longitude
  		marker.picture({
  			url: ActionController::Base.helpers.asset_path('map_pin.png'),
  			width: 22,
  			height: 42
        })
  		marker.json({flight_id:flight.id})
  		marker.infowindow render_to_string(:partial => "pages/maker_template", :locals => { :object => flight})
	end

	@cluster_image = ActionController::Base.helpers.asset_path("logo.png", type: :image)

	#build polylines
	@polylines = Array.new
	@trips.each do |trip|
		trip.flights.map{|flight| 
			a_airport = Airport.find(flight.arrival_airport)
			d_airport = Airport.find(flight.depart_airport)
			hex = "%06x" % (rand * 0xffffff)
			color = "##{hex}"
			@polylines << 
			[
				{lng:d_airport.longitude, lat:d_airport.latitude},{lng:a_airport.longitude, lat:a_airport.latitude}
			]
		}
	end
	@polylines = @polylines.to_json
  end

  def index

  end
  

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
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
end
