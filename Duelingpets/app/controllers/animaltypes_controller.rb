class AnimaltypesController < ApplicationController
  before_action :set_animaltype, only: [:show, :edit, :update, :destroy]

  # GET /animaltypes
  # GET /animaltypes.json
  def index
    @animaltypes = Animaltype.all
  end

  # GET /animaltypes/1
  # GET /animaltypes/1.json
  def show
  end

  # GET /animaltypes/new
  def new
    @animaltype = Animaltype.new
  end

  # GET /animaltypes/1/edit
  def edit
  end

  # POST /animaltypes
  # POST /animaltypes.json
  def create
    @animaltype = Animaltype.new(animaltype_params)

    respond_to do |format|
      if @animaltype.save
        format.html { redirect_to @animaltype, notice: 'Animaltype was successfully created.' }
        format.json { render :show, status: :created, location: @animaltype }
      else
        format.html { render :new }
        format.json { render json: @animaltype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /animaltypes/1
  # PATCH/PUT /animaltypes/1.json
  def update
    respond_to do |format|
      if @animaltype.update(animaltype_params)
        format.html { redirect_to @animaltype, notice: 'Animaltype was successfully updated.' }
        format.json { render :show, status: :ok, location: @animaltype }
      else
        format.html { render :edit }
        format.json { render json: @animaltype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /animaltypes/1
  # DELETE /animaltypes/1.json
  def destroy
    @animaltype.destroy
    respond_to do |format|
      format.html { redirect_to animaltypes_url, notice: 'Animaltype was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_animaltype
      @animaltype = Animaltype.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def animaltype_params
      params.require(:animaltype).permit(:name)
    end
end
