class FlightFixesController < ApplicationController
  before_action :set_flight_fix, only: [:show, :edit, :update, :destroy]

  # GET /flight_fixes
  # GET /flight_fixes.json
  def index
    @flight_fixes = FlightFix.all
  end

  # GET /flight_fixes/1
  # GET /flight_fixes/1.json
  def show
  end

  # GET /flight_fixes/new
  def new
    @flight_fix = FlightFix.new
  end

  # GET /flight_fixes/1/edit
  def edit
  end

  # POST /flight_fixes
  # POST /flight_fixes.json
  def create
    @flight_fix = FlightFix.new(flight_fix_params)

    respond_to do |format|
      if @flight_fix.save
        format.html { redirect_to @flight_fix, notice: 'Flight fix was successfully created.' }
        format.json { render action: 'show', status: :created, location: @flight_fix }
      else
        format.html { render action: 'new' }
        format.json { render json: @flight_fix.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /flight_fixes/1
  # PATCH/PUT /flight_fixes/1.json
  def update
    respond_to do |format|
      if @flight_fix.update(flight_fix_params)
        format.html { redirect_to @flight_fix, notice: 'Flight fix was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @flight_fix.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /flight_fixes/1
  # DELETE /flight_fixes/1.json
  def destroy
    @flight_fix.destroy
    respond_to do |format|
      format.html { redirect_to flight_fixes_url }
      format.json { head :no_content }
    end
  end

  def fixup
    am_ids = AirportMapping.where("airport_id IS NOT NULL").map{|am| am.id}
    ffs = FlightFix.where(airline_mapping_id: am_ids).select{|am| Flight.where("id = ?", am.flight_id).count > 0}
    ffs.each do |flightfix|
      flight = Flight.find(flightfix.flight_id)
      aid = AirportMapping.find(flightfix.airline_mapping_id).airport_id
      if flightfix.direction == 1
        flight.depart_airport = aid
      else
        flight.arrival_airport = aid
      end
      flight.save
      flightfix.destroy
    end
    redirect_to flight_fixes_path, notice: 'Flight fixes were updated'
  end

  def cleardead
    #am_ids = AirportMapping.all.map{|am| am.id}
    FlightFix.all.each do |ff|
      ff.destroy if Flight.where("id = ?", ff.flight_id).count < 1
    end
    redirect_to flight_fixes_path, notice: 'Deleted All FlightFixes w/out a Flight'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_flight_fix
      @flight_fix = FlightFix.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def flight_fix_params
      params.require(:flight_fix).permit(:airline_mapping_id, :flight_id, :direction, :status, :trip_id)
    end

end
