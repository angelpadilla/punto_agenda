class Admin::CorpsController < AdminController
  before_action :set_corp, only: %i[show edit update]

  def index
    corps = Corp.default

    @q = corps.ransack(params[:q])
    @pagy, @corps = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
  end

  def edit
  end

  def update
    if @corp.update(corp_params)
      redirect_to admin_corp_path(@corp), notice: "Cliente actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_corp
    @corp = Corp.find(params[:id])
  end

  def corp_params
    params.require(:corp).permit(:name, :rfc, :email, :tel, :address, :sku)
  end
end