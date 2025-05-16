class EquipmentController < ApplicationController
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]
  before_action :check_equipment_owner, only: [:show, :edit, :update, :destroy]
  before_action :no_index

  def index
    @equipment = current_user.equipment.order(created_at: :desc)
    @title = "Equipment"

    respond_to do |format|
      format.html
      format.csv { send_data equipment_to_csv, filename: "equipment-#{Date.today}.csv" }
    end
  end

  def show
    @inspections = @equipment.inspections.order(inspection_date: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: { id: @equipment.id, name: @equipment.name, serial: @equipment.serial, location: @equipment.location, manufacturer: @equipment.manufacturer } }
    end
  end

  def new
    @equipment = Equipment.new
  end

  def create
    @equipment = current_user.equipment.build(equipment_params)

    if @equipment.save
      flash[:success] = "Equipment record created"
      redirect_to @equipment
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @equipment.update(equipment_params)
      flash[:success] = "Equipment record updated"
      redirect_to @equipment
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    flash[:success] = "Equipment record deleted"
    redirect_to equipment_index_path
  end

  def search
    @equipment = params[:query].present? ?
      current_user.equipment.search(params[:query]) :
      current_user.equipment
  end

  private

  def equipment_params
    params.require(:equipment).permit(:name, :location, :serial, :manufacturer)
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_equipment
    @equipment = Equipment.find_by(id: params[:id].downcase)

    unless @equipment
      flash[:danger] = "Equipment record not found"
      redirect_to equipment_index_path and return
    end
  end

  def check_equipment_owner
    unless @equipment.user_id == current_user.id
      flash[:danger] = "Access denied"
      redirect_to equipment_index_path and return
    end
  end

  def equipment_to_csv
    attributes = %w[id name manufacturer location serial]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      current_user.equipment.order(created_at: :desc).each do |equipment|
        row = attributes.map { |attr| equipment.send(attr) }
        csv << row
      end
    end
  end
end
