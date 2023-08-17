class CharacterstatsController < ApplicationController
  before_action :set_characterstat, only: [:show, :edit, :update, :destroy]

  # GET /characterstats
  # GET /characterstats.json
  def index
    @characterstats = Characterstat.all
  end

  # GET /characterstats/1
  # GET /characterstats/1.json
  def show
  end

  # GET /characterstats/new
  def new
    @characterstat = Characterstat.new
  end

  # GET /characterstats/1/edit
  def edit
  end

  # POST /characterstats
  # POST /characterstats.json
  def create
    @characterstat = Characterstat.new(characterstat_params)

    respond_to do |format|
      if @characterstat.save
        format.html { redirect_to @characterstat, notice: 'Characterstat was successfully created.' }
        format.json { render :show, status: :created, location: @characterstat }
      else
        format.html { render :new }
        format.json { render json: @characterstat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /characterstats/1
  # PATCH/PUT /characterstats/1.json
  def update
    respond_to do |format|
      if @characterstat.update(characterstat_params)
        format.html { redirect_to @characterstat, notice: 'Characterstat was successfully updated.' }
        format.json { render :show, status: :ok, location: @characterstat }
      else
        format.html { render :edit }
        format.json { render json: @characterstat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /characterstats/1
  # DELETE /characterstats/1.json
  def destroy
    @characterstat.destroy
    respond_to do |format|
      format.html { redirect_to characterstats_url, notice: 'Characterstat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_characterstat
      @characterstat = Characterstat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def characterstat_params
      params.require(:characterstat).permit(:value, :character_id, :stat_id)
    end
end
