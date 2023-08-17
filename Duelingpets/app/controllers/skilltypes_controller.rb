class SkilltypesController < ApplicationController
  before_action :set_skilltype, only: [:show, :edit, :update, :destroy]

  # GET /skilltypes
  # GET /skilltypes.json
  def index
    @skilltypes = Skilltype.all
  end

  # GET /skilltypes/1
  # GET /skilltypes/1.json
  def show
  end

  # GET /skilltypes/new
  def new
    @skilltype = Skilltype.new
  end

  # GET /skilltypes/1/edit
  def edit
  end

  # POST /skilltypes
  # POST /skilltypes.json
  def create
    @skilltype = Skilltype.new(skilltype_params)

    respond_to do |format|
      if @skilltype.save
        format.html { redirect_to @skilltype, notice: 'Skilltype was successfully created.' }
        format.json { render :show, status: :created, location: @skilltype }
      else
        format.html { render :new }
        format.json { render json: @skilltype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /skilltypes/1
  # PATCH/PUT /skilltypes/1.json
  def update
    respond_to do |format|
      if @skilltype.update(skilltype_params)
        format.html { redirect_to @skilltype, notice: 'Skilltype was successfully updated.' }
        format.json { render :show, status: :ok, location: @skilltype }
      else
        format.html { render :edit }
        format.json { render json: @skilltype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /skilltypes/1
  # DELETE /skilltypes/1.json
  def destroy
    @skilltype.destroy
    respond_to do |format|
      format.html { redirect_to skilltypes_url, notice: 'Skilltype was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_skilltype
      @skilltype = Skilltype.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def skilltype_params
      params.require(:skilltype).permit(:name)
    end
end
