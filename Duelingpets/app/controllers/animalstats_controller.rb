class AnimalstatsController < ApplicationController
  before_action :set_animalstat, only: [:show, :edit, :update, :destroy]

  # GET /animalstats
  # GET /animalstats.json
  def index
    @animalstats = Animalstat.all
  end

  # GET /animalstats/1
  # GET /animalstats/1.json
  def show
  end

  # GET /animalstats/new
  def new
    @animalstat = Animalstat.new
  end

  # GET /animalstats/1/edit
  def edit
  end

  # POST /animalstats
  # POST /animalstats.json
  def create
    @animalstat = Animalstat.new(animalstat_params)

    respond_to do |format|
      if @animalstat.save
        format.html { redirect_to @animalstat, notice: 'Animalstat was successfully created.' }
        format.json { render :show, status: :created, location: @animalstat }
      else
        format.html { render :new }
        format.json { render json: @animalstat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /animalstats/1
  # PATCH/PUT /animalstats/1.json
  def update
    respond_to do |format|
      if @animalstat.update(animalstat_params)
        format.html { redirect_to @animalstat, notice: 'Animalstat was successfully updated.' }
        format.json { render :show, status: :ok, location: @animalstat }
      else
        format.html { render :edit }
        format.json { render json: @animalstat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /animalstats/1
  # DELETE /animalstats/1.json
  def destroy
    @animalstat.destroy
    respond_to do |format|
      format.html { redirect_to animalstats_url, notice: 'Animalstat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_animalstat
      @animalstat = Animalstat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def animalstat_params
      params.require(:animalstat).permit(:value, :animaltype_id, :stat_id)
    end
end
