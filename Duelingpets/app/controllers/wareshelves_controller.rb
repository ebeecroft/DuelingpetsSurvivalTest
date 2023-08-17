class WareshelvesController < ApplicationController
  before_action :set_wareshelf, only: [:show, :edit, :update, :destroy]

  # GET /wareshelves
  # GET /wareshelves.json
  def index
    @wareshelves = Wareshelf.all
  end

  # GET /wareshelves/1
  # GET /wareshelves/1.json
  def show
  end

  # GET /wareshelves/new
  def new
    @wareshelf = Wareshelf.new
  end

  # GET /wareshelves/1/edit
  def edit
  end

  # POST /wareshelves
  # POST /wareshelves.json
  def create
    @wareshelf = Wareshelf.new(wareshelf_params)

    respond_to do |format|
      if @wareshelf.save
        format.html { redirect_to @wareshelf, notice: 'Wareshelf was successfully created.' }
        format.json { render :show, status: :created, location: @wareshelf }
      else
        format.html { render :new }
        format.json { render json: @wareshelf.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wareshelves/1
  # PATCH/PUT /wareshelves/1.json
  def update
    respond_to do |format|
      if @wareshelf.update(wareshelf_params)
        format.html { redirect_to @wareshelf, notice: 'Wareshelf was successfully updated.' }
        format.json { render :show, status: :ok, location: @wareshelf }
      else
        format.html { render :edit }
        format.json { render json: @wareshelf.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wareshelves/1
  # DELETE /wareshelves/1.json
  def destroy
    @wareshelf.destroy
    respond_to do |format|
      format.html { redirect_to wareshelves_url, notice: 'Wareshelf was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wareshelf
      @wareshelf = Wareshelf.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def wareshelf_params
      params.require(:wareshelf).permit(:waretype, :warelimit, :warehouse_id)
    end
end
