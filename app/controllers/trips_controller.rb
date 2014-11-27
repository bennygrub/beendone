class TripsController < ApplicationController
  include ApplicationHelper
  helper_method :admin
  before_action :set_trip, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:show]
  before_action :admin, only: [:index]
  skip_before_action :verify_authenticity_token
  autocomplete :airport, :city, :extra_data => [:faa], :display_value => :funky_method#, :full => true
  # GET /tripes
  # GET /tripes.json
  def index
    @trips = initialize_grid(Trip.all)
  end

  # GET /tripes/1
  # GET /tripes/1.json
  def show
    @map_page = true
    @user = User.find(@trip.user_id)
    @destination = destination_city(@trip)
    @num_of_visits = @user.flights.where("arrival_airport = ?", @destination.id).select{|flight| is_destination(flight)}
    if @trip.cover.blank? 
      @cover = @destination.avatar.url
    else
      @cover = @trip.cover.url
    end
    @arrive = @trip.flights.first.arrival_time
    @depart = @trip.flights.last.depart_time
    #@arrive = 3.years.ago
    #@depart = Time.now
    @highlight = Highlight.new
    @mate = Mate.new
    @place = Place.new
    @categories = Category.all
    @user_check = @user.id == current_user.id if current_user#checks to if the current user owns the trip
    @auth_check = @user.authentications.where("provider = ?", "instagram").count != 0 #check if the user has instagram auth
    if @auth_check
      @client = Instagram.client(:access_token => @user.authentications.where("provider = ?", "instagram").first.token)
      @instagram_photos = @client.user_recent_media(:min_timestamp => @arrive.to_i, :max_timestamp => @depart.to_i)
      #@instagram_photos = @client.user_recent_media(:min_timestamp => 3.years.ago.to_i, :max_timestamp => Time.now.to_i)
      @instas = @instagram_photos.map{|media_item| media_item.images.standard_resolution.url}
    end
    @facebook_check = @user.authentications.where("provider = ?", "facebook").count != 0 #check if the user has instagram auth
    @twitter_check = @user.authentications.where("provider = ?", "twitter").count != 0 #check if the user has instagram auth
    if @twitter_check
      @twit_auth = @user.authentications.where("provider = ?", "twitter")
      client = Twitter::REST::Client.new do |config|
        if Rails.env.development?
          config.consumer_key        = "KXxqcOE3eqI6sddRyavNeHTtL"
          config.consumer_secret     = "ZLDWYmWOzP7cU26BjJe3NPflNRu9iRtYwy6RMDD8RTUWGRMxNH"
        else
          config.consumer_key        = "lIsxQnuCiG9kwNvOJwsjFg3ao"
          config.consumer_secret     = "GTR5WZzZIqllS07wK1jsWsyKeDFX6qxBg9oVdGufbOJA1lHGL3"
        end        
        config.access_token        = @twit_auth.first.token
        config.access_token_secret = @twit_auth.first.secret
      end
      @tweets = client.user_timeline(:since_id => @arrive.to_i, :max_id => @depart.to_i)
      #@tweets = client.user_timeline
    end
    if @facebook_check
      @fb_auth = @user.authentications.where("provider = ?", "facebook").first
      @statuses = FbGraph::User.me(@fb_auth.token).statuses(:until => @arrive.to_i, :since => @depart.to_i)
      #@statuses = FbGraph::User.me(@fb_auth.token).statuses(:until => Time.now.to_i, :since => 3.years.ago.to_i)
    end
  end

  # GET /tripes/new
  def new
    @trip = Trip.new
    @trip.flights.build
    @airlines = Airline.all.order('name ASC')
    #@airports = Airport.where("faa is NOT NULL").order('city ASC')
  end

  # GET /tripes/1/edit
  def edit
  end

  # POST /tripes
  # POST /tripes.json
  def create

    begin 
      d_ports = trip_params[:flights_attributes].map{|f| f[1][:depart_airport].scan(/\((.*?)\)/).first.first }
      a_ports = trip_params[:flights_attributes].map{|f| f[1][:arrival_airport].scan(/\((.*?)\)/).first.first }
      ports = d_ports + a_ports
      ports.map{|f| Airport.find_by_faa(f)}        

      @trip = Trip.create(user_id: current_user.id, name: trip_params[:name])
      trip_params[:flights_attributes].each do |flight|
        d = flight[1][:depart_time].split('/')
        a = flight[1][:arrival_time].split('/')
        depart_airport = Airport.find_by_faa(flight[1][:depart_airport].scan(/\((.*?)\)/).first.first).id
        arrival_airport = Airport.find_by_faa(flight[1][:arrival_airport].scan(/\((.*?)\)/).first.first).id
        depart_time = DateTime.new(d[2].to_i, d[0].to_i,d[1].to_i,11,30, 0, 0)
        arrival_time = DateTime.new(a[2].to_i, a[0].to_i,a[1].to_i,16,30, 0, 0)
        Flight.create(
          airline_id: flight[1][:airline_id],
          trip_id: @trip.id,
          depart_airport: depart_airport,
          arrival_airport: arrival_airport,
          depart_time: depart_time,
          arrival_time: arrival_time
        )
      end
    
      redirect_to @trip, notice: 'Trip was Created'
    rescue
      redirect_to new_trip_path, notice: 'Please select a listed airport with FAA code'
    end
  end

  # PATCH/PUT /tripes/1
  # PATCH/PUT /tripes/1.json
  def update
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to @trip, notice: 'Trip was successfully updated.' }
        format.json { head :no_content }
        format.js
      else
        format.html { render action: 'edit' }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /tripes/1
  # DELETE /tripes/1.json
  def destroy
    @trip.destroy
    respond_to do |format|
      format.html { redirect_to tripes_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trip
      @trip = Trip.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trip_params
      params.require(:trip).permit(:user_id, :name, :message_id, :description, :cover, flights_attributes: [:id, :airline_id, :trip_id, :depart_airport, :arrival_airport, :depart_time, :arrival_time])
    end
    def get_autocomplete_items(parameters)
      super(parameters).where("faa IS NOT NULL")
    end
end
