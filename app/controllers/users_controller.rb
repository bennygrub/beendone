class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :share]
  include ApplicationHelper
  helper_method :admin
  before_action :authenticate_user!, only: [:index] 
  before_action :admin, only: [:index]
  def edit
  end

  def index
    @users = initialize_grid(User.all)
  end

  def share
    @trips = @user.trips.select{|trip| trip.flights.count > 0}
    @destiny = @trips.map{|trip|{lon: find_destination(trip).longitude, lat: find_destination(trip).latitude} }
    @markers = @destiny.map{|d| "&markers=color:green%7Clabel:one%7C#{d[:lat]},#{d[:lon]}"  }
    @markers = @markers.each_with_index.map{|m, i| m if i <25  }.compact
    #base = "https://maps.googleapis.com/maps/api/staticmap?center=auto&zoom=auto&size=600x300&maptype=roadmap"#world view
    base = "https://maps.googleapis.com/maps/api/staticmap?size=600x300&maptype=roadmap"#auto zoom and center
    markers = @markers.join
    style = "&style=feature:administrative|element:all|visibility:off&style=feature:administrative.country|element:geometry.stroke|visibility:on|color:0x1c1d1f|weight:0.5&style=feature:water|element:all|color:0x2e2e31&style=feature:landscape|element:all|color:0xdddddd&style=feature:poi|element:all|color:0xdddddd&style=feature:road|element:all|visibility:off&style=feature:transit|element:all|visibility:off&style=feature:all|element:labels|visibility:off"
    @map_url = base+markers+style
  end

  def show
    @map_page = true
  	@trips = @user.trips#all trips from current_user
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
    @airlines = @user.flights.map{|flight| Airline.find(flight.airline_id).name}.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.sort_by{ |key, value| -value }


  	@flights = @user.flights
    d_airport_ids = @flights.map{|f| f.depart_airport}
    a_airport_ids = @flights.map{|f| f.arrival_airport}
    aa = (a_airport_ids + d_airport_ids).uniq

    @all = aa.map{|a_id|
      port = Airport.find(a_id)
      OpenStruct.new(
        {
          latitude: port.latitude, 
          longitude: port.longitude, 
          a_id: a_id,
          name: port.name,
          city: port.city,
        }
      )
    }
    citypin = ActionController::Base.helpers.asset_path("citypin.png", type: :image)
    @hash = Gmaps4rails.build_markers(@all) do |flight, marker|
      marker.lat flight.latitude
      marker.lng flight.longitude
      marker.shadow [10, true]
      #marker.picture({url: ActionController::Base.helpers.asset_path('map_pin.png'),width: 22,height: 42})
      marker.json({custom_marker: "<div class='map-marker'><div class='map-city'><span class='map-city-pin'><img style='max-width:17px;padding: 0 3px 3px 0;' src='#{citypin}'></span>#{flight.city}</div></div><div class='mm-bot'>Visited:</div><div class='arrow-space'></div>"})
      marker.infowindow render_to_string(:partial => "users/info_box", :locals => { :object => flight})
    end


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
    ##25ce98
    
    @user_check = @user.id == current_user.id if current_user
    @auth_check = @user.authentications.where("provider = ?", "instagram").count == 0 #check if the user has instagram auth
    @client = Instagram.client(:access_token => @user.authentications.where("provider = ?", "instagram").first.token) unless @auth_check
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
