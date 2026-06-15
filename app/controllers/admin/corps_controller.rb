class Admin::CorpsController < AdminController
  before_action :set_corp, only: %i[show edit update extend_prueba]

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

  def extend_prueba
    ## extendemos 30 dias mas de prueba, y  con status premium y payment attempts  0
    noww = Time.current

    @corp.update(
      status: :probando,
      tipo_plan: :premium,
      subscription_trial_start: noww,
      subscription_trial_end: 30.days.from_now,
      subscription_started_at: nil,
      subscription_next_billing_date: nil,
      payment_attempts: 0,
    )
    redirect_back fallback_location: admin_corp_path(@corp), notice: "Prueba extendada 30 días exitosamente."
  end

  private

  def set_corp
    @corp = Corp.find(params[:id])
  end

  def corp_params
    params.require(:corp).permit(:name, :rfc, :email, :tel, :address, :sku)
  end
end