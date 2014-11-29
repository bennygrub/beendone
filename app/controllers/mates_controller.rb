class MatesController < ApplicationController
  before_action :set_mate, only: [:show, :edit, :update, :destroy]

  # GET /mates
  # GET /mates.json
  def index
    @mates = Mate.all
  end

  # GET /mates/1
  # GET /mates/1.json
  def show
  end

  # GET /mates/new
  def new
    @mate = Mate.new
  end

  # GET /mates/1/edit
  def edit
  end

  # POST /mates
  # POST /mates.json
  def create
    @mate = Mate.new(mate_params)
    respond_to do |format|
      if @mate.save
        format.html { redirect_to trip_path(@mate.trip_id), notice: 'Your Trip Mate was successfully created.' }
        format.json { render action: 'show', status: :created, location: @mate }
      else
        format.html { redirect_to trip_path(@mate.trip_id), notice: "#{@mate.errors.full_messages.map{|m| m}}" }
        format.json { render json: @mate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mates/1
  # PATCH/PUT /mates/1.json
  def update
    respond_to do |format|
      if @mate.update(mate_params)
        format.html { redirect_to @mate, notice: 'Mate was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @mate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mates/1
  # DELETE /mates/1.json
  def destroy
    @mate.destroy
    respond_to do |format|
      format.html { redirect_to trip_path(@mate.trip_id) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mate
      @mate = Mate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def mate_params
      params.require(:mate).permit(:trip_id, :email, :name, :email_user, :user_id)
    end
end
