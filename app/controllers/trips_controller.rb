class TripsController < ApplicationController
  include ApplicationHelper
  helper_method :admin
  before_action :set_trip, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :admin
  # GET /tripes
  # GET /tripes.json
  def index
    @tripes = Trip.all
  end

  # GET /tripes/1
  # GET /tripes/1.json
  def show
    @map_page = true
    @destination = destination_city(@trip)
  end

  # GET /tripes/new
  def new
    @trip = Trip.new
  end

  # GET /tripes/1/edit
  def edit
  end

  # POST /tripes
  # POST /tripes.json
  def create
    @trip = Trip.new(trip_params)

    respond_to do |format|
      if @trip.save
        format.html { redirect_to @trip, notice: 'Flight fix was successfully created.' }
        format.json { render action: 'show', status: :created, location: @trip }
      else
        format.html { render action: 'new' }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tripes/1
  # PATCH/PUT /tripes/1.json
  def update
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to @trip, notice: 'Flight fix was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
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
      params.require(:trip).permit(:user_id, :name, :message_id)
    end

end
