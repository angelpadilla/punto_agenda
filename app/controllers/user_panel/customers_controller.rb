class UserPanel::CustomersController < UserPanelController
  before_action :set_customer, only: %i[ show edit update destroy ]

  def index
    customers = @corp.customers.default

    @q = customers.ransack(params[:q])
    @pagy, @customers = pagy(@q.result(distinct: true), limit: 10)
  end

  def show
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    token = Generatepass.gen(exclude_ambiguous: true, include_symbols: false, length: 8)
    @customer = @corp.customers.new(customer_params)
    @customer.password = token
    @customer.password_confirmation = token
    @customer.passs = token

    respond_to do |format|
      if @customer.save
        format.html { redirect_to customers_path, notice: "Cliente creado." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to customers_path, notice: "Cliente actualizado.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Cliente eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def destroy_doc
    @customer.docs.find(params[:doc_id]).purge_later

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_customer
    @customer = @corp.customers.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def customer_params
    params.expect(customer: [
      :active,
      :calle,
      :ciudad,
      :colonia,
      :corp_id,
      :cp,
      :curp,
      :email,
      :estado,
      :num_ext,
      :num_int,
      :razon,
      :regimen,
      :rfc,
      :tel,
      :tel_prefix,
      :tipo,
      :limite_credito,
      :notas,
      docs: []
    ])
  end
end
