class CurrencylevelsController < ApplicationController
  before_action :set_currencylevel, only: [:show, :edit, :update, :destroy]

  # GET /currencylevels
  # GET /currencylevels.json
  def index
    @currencylevels = Currencylevel.all
  end

  # GET /currencylevels/1
  # GET /currencylevels/1.json
  def show
  end

  # GET /currencylevels/new
  def new
    @currencylevel = Currencylevel.new
  end

  # GET /currencylevels/1/edit
  def edit
  end

  # POST /currencylevels
  # POST /currencylevels.json
  def create
    @currencylevel = Currencylevel.new(currencylevel_params)

    respond_to do |format|
      if @currencylevel.save
        format.html { redirect_to @currencylevel, notice: 'Currencylevel was successfully created.' }
        format.json { render :show, status: :created, location: @currencylevel }
      else
        format.html { render :new }
        format.json { render json: @currencylevel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /currencylevels/1
  # PATCH/PUT /currencylevels/1.json
  def update
    respond_to do |format|
      if @currencylevel.update(currencylevel_params)
        format.html { redirect_to @currencylevel, notice: 'Currencylevel was successfully updated.' }
        format.json { render :show, status: :ok, location: @currencylevel }
      else
        format.html { render :edit }
        format.json { render json: @currencylevel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /currencylevels/1
  # DELETE /currencylevels/1.json
  def destroy
    @currencylevel.destroy
    respond_to do |format|
      format.html { redirect_to currencylevels_url, notice: 'Currencylevel was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_currencylevel
      @currencylevel = Currencylevel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def currencylevel_params
      params.require(:currencylevel).permit(:name)
    end
end
