class UserPanel::ProvidersController < UserPanelController
  before_action :set_provider, only: %i[ show edit update destroy ]

  def index
    providers = @corp.providers.default

    @q = providers.ransack(params[:q])
    @pagy, @providers = pagy(@q.result(distinct: true), limit: 10)
  end

  def show
  end

  def new
    @provider = Provider.new
  end

  def edit
    puts "Editing provider: #{@provider.id}"
  end

  def create
    @provider = @corp.providers.new(provider_params)

    respond_to do |format|
      if @provider.save
        format.html { redirect_to providers_path, notice: "Proveedor creado." }
        format.json { render :show, status: :created, location: @provider }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @provider.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @provider.update(provider_params)
        format.html { redirect_to providers_path, notice: "Proveedor actualizado.", status: :see_other }
        format.json { render :show, status: :ok, location: @provider }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @provider.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @provider.destroy
    respond_to do |format|
      format.html { redirect_to providers_path, notice: "Proveedor eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def destroy_doc
    @provider.docs.find(params[:doc_id]).purge_later

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_provider
    @provider = @corp.providers.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def provider_params
    params.expect(provider: [
      :calle,
      :ciudad,
      :colonia,
      :corp_id,
      :cp,
      :email,
      :estado,
      :num_ext,
      :num_int,
      :razon,
      :regimen,
      :rfc,
      :tel,
      :notas
    ])
  end
end
