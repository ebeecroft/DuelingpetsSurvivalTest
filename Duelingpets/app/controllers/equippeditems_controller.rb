class EquippeditemsController < ApplicationController
  before_action :set_equippeditem, only: [:show, :edit, :update, :destroy]

  # GET /equippeditems
  # GET /equippeditems.json
  def index
    @equippeditems = Equippeditem.all
  end

  # GET /equippeditems/1
  # GET /equippeditems/1.json
  def show
  end

  # GET /equippeditems/new
  def new
    @equippeditem = Equippeditem.new
  end

  # GET /equippeditems/1/edit
  def edit
  end

  # POST /equippeditems
  # POST /equippeditems.json
  def create
    @equippeditem = Equippeditem.new(equippeditem_params)

    respond_to do |format|
      if @equippeditem.save
        format.html { redirect_to @equippeditem, notice: 'Equippeditem was successfully created.' }
        format.json { render :show, status: :created, location: @equippeditem }
      else
        format.html { render :new }
        format.json { render json: @equippeditem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /equippeditems/1
  # PATCH/PUT /equippeditems/1.json
  def update
    respond_to do |format|
      if @equippeditem.update(equippeditem_params)
        format.html { redirect_to @equippeditem, notice: 'Equippeditem was successfully updated.' }
        format.json { render :show, status: :ok, location: @equippeditem }
      else
        format.html { render :edit }
        format.json { render json: @equippeditem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /equippeditems/1
  # DELETE /equippeditems/1.json
  def destroy
    @equippeditem.destroy
    respond_to do |format|
      format.html { redirect_to equippeditems_url, notice: 'Equippeditem was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equippeditem
      @equippeditem = Equippeditem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def equippeditem_params
      params.require(:equippeditem).permit(:current_durability, :initial_durability, :equip_id, :item_id)
    end
end
