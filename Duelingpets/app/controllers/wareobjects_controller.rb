class WareobjectsController < ApplicationController
  before_action :set_wareobject, only: [:show, :edit, :update, :destroy]

  # GET /wareobjects
  # GET /wareobjects.json
  def index
    @wareobjects = Wareobject.all
  end

  # GET /wareobjects/1
  # GET /wareobjects/1.json
  def show
  end

  # GET /wareobjects/new
  def new
    @wareobject = Wareobject.new
  end

  # GET /wareobjects/1/edit
  def edit
  end

  # POST /wareobjects
  # POST /wareobjects.json
  def create
    @wareobject = Wareobject.new(wareobject_params)

    respond_to do |format|
      if @wareobject.save
        format.html { redirect_to @wareobject, notice: 'Wareobject was successfully created.' }
        format.json { render :show, status: :created, location: @wareobject }
      else
        format.html { render :new }
        format.json { render json: @wareobject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wareobjects/1
  # PATCH/PUT /wareobjects/1.json
  def update
    respond_to do |format|
      if @wareobject.update(wareobject_params)
        format.html { redirect_to @wareobject, notice: 'Wareobject was successfully updated.' }
        format.json { render :show, status: :ok, location: @wareobject }
      else
        format.html { render :edit }
        format.json { render json: @wareobject.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wareobjects/1
  # DELETE /wareobjects/1.json
  def destroy
    @wareobject.destroy
    respond_to do |format|
      format.html { redirect_to wareobjects_url, notice: 'Wareobject was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wareobject
      @wareobject = Wareobject.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def wareobject_params
      params.require(:wareobject).permit(:type, :price, :quantity, :wareshelf_id, :wareobject_id)
    end
end
