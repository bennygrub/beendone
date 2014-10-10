class AirportMappingsController < ApplicationController
  before_action :set_airport_mapping, only: [:show, :edit, :update, :destroy]

  # GET /airport_mappings
  # GET /airport_mappings.json
  def index
    @airport_mappings = AirportMapping.all
  end

  # GET /airport_mappings/1
  # GET /airport_mappings/1.json
  def show
  end

  # GET /airport_mappings/new
  def new
    @airport_mapping = AirportMapping.new
  end

  # GET /airport_mappings/1/edit
  def edit
  end

  # POST /airport_mappings
  # POST /airport_mappings.json
  def create
    @airport_mapping = AirportMapping.new(airport_mapping_params)

    respond_to do |format|
      if @airport_mapping.save
        format.html { redirect_to @airport_mapping, notice: 'Airport mapping was successfully created.' }
        format.json { render action: 'show', status: :created, location: @airport_mapping }
      else
        format.html { render action: 'new' }
        format.json { render json: @airport_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /airport_mappings/1
  # PATCH/PUT /airport_mappings/1.json
  def update
    respond_to do |format|
      if @airport_mapping.update(airport_mapping_params)
        format.html { redirect_to @airport_mapping, notice: 'Airport mapping was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @airport_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /airport_mappings/1
  # DELETE /airport_mappings/1.json
  def destroy
    @airport_mapping.destroy
    respond_to do |format|
      format.html { redirect_to airport_mappings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_airport_mapping
      @airport_mapping = AirportMapping.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def airport_mapping_params
      params.require(:airport_mapping).permit(:name, :city, :airport_id, :airline_id, :message_id, :note)
    end
end
