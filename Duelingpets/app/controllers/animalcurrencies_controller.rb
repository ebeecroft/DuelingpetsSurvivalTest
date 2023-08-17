class AnimalcurrenciesController < ApplicationController
  before_action :set_animalcurrency, only: [:show, :edit, :update, :destroy]

  # GET /animalcurrencies
  # GET /animalcurrencies.json
  def index
    @animalcurrencies = Animalcurrency.all
  end

  # GET /animalcurrencies/1
  # GET /animalcurrencies/1.json
  def show
  end

  # GET /animalcurrencies/new
  def new
    @animalcurrency = Animalcurrency.new
  end

  # GET /animalcurrencies/1/edit
  def edit
  end

  # POST /animalcurrencies
  # POST /animalcurrencies.json
  def create
    @animalcurrency = Animalcurrency.new(animalcurrency_params)

    respond_to do |format|
      if @animalcurrency.save
        format.html { redirect_to @animalcurrency, notice: 'Animalcurrency was successfully created.' }
        format.json { render :show, status: :created, location: @animalcurrency }
      else
        format.html { render :new }
        format.json { render json: @animalcurrency.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /animalcurrencies/1
  # PATCH/PUT /animalcurrencies/1.json
  def update
    respond_to do |format|
      if @animalcurrency.update(animalcurrency_params)
        format.html { redirect_to @animalcurrency, notice: 'Animalcurrency was successfully updated.' }
        format.json { render :show, status: :ok, location: @animalcurrency }
      else
        format.html { render :edit }
        format.json { render json: @animalcurrency.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /animalcurrencies/1
  # DELETE /animalcurrencies/1.json
  def destroy
    @animalcurrency.destroy
    respond_to do |format|
      format.html { redirect_to animalcurrencies_url, notice: 'Animalcurrency was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_animalcurrency
      @animalcurrency = Animalcurrency.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def animalcurrency_params
      params.require(:animalcurrency).permit(:animaltype_id, :currencylevel_id, :currency_id)
    end
end
