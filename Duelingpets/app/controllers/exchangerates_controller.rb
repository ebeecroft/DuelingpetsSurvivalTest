class ExchangeratesController < ApplicationController
  before_action :set_exchangerate, only: [:show, :edit, :update, :destroy]

  # GET /exchangerates
  # GET /exchangerates.json
  def index
    @exchangerates = Exchangerate.all
  end

  # GET /exchangerates/1
  # GET /exchangerates/1.json
  def show
  end

  # GET /exchangerates/new
  def new
    @exchangerate = Exchangerate.new
  end

  # GET /exchangerates/1/edit
  def edit
  end

  # POST /exchangerates
  # POST /exchangerates.json
  def create
    @exchangerate = Exchangerate.new(exchangerate_params)

    respond_to do |format|
      if @exchangerate.save
        format.html { redirect_to @exchangerate, notice: 'Exchangerate was successfully created.' }
        format.json { render :show, status: :created, location: @exchangerate }
      else
        format.html { render :new }
        format.json { render json: @exchangerate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exchangerates/1
  # PATCH/PUT /exchangerates/1.json
  def update
    respond_to do |format|
      if @exchangerate.update(exchangerate_params)
        format.html { redirect_to @exchangerate, notice: 'Exchangerate was successfully updated.' }
        format.json { render :show, status: :ok, location: @exchangerate }
      else
        format.html { render :edit }
        format.json { render json: @exchangerate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exchangerates/1
  # DELETE /exchangerates/1.json
  def destroy
    @exchangerate.destroy
    respond_to do |format|
      format.html { redirect_to exchangerates_url, notice: 'Exchangerate was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exchangerate
      @exchangerate = Exchangerate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exchangerate_params
      params.require(:exchangerate).permit(:currency1_id, :currency2_id, :minrate, :currentrate, :maxrate)
    end
end
