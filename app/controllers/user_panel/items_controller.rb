class UserPanel::ItemsController < UserPanelController
  before_action :set_item, only: %i[ show edit update destroy ]
  before_action :validate_corp, only: %i[ show edit update destroy ]
  before_action :validate_item, only: %i[ show edit update destroy ]

  # GET /items or /items.json
  def index
    @brands = Rails.cache.fetch("brands_for_items_index", expires_in: 1.month) do
      @corp.brands.default
    end

    items = @corp.items.default.includes(
      :brand,
      img1_attachment: :blob,
      img2_attachment: :blob,
      img3_attachment: :blob,
      img4_attachment: :blob,
      img5_attachment: :blob
    )

    @q = items.ransack(params[:q])
    @pagy, @items = pagy(@q.result(distinct: true), limit: 25)
  end

  # GET /items/1 or /items/1.json
  def show
  end

  # GET /items/new
  def new
    @item = Item.new
  end

  # GET /items/1/edit
  def edit
  end

  # POST /items or /items.json
  def create
    @item = @corp.items.new(item_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to item_path(@item), notice: "Item creado." }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1 or /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        format.html { redirect_to item_path(@item), notice: "Item actualizado.", status: :see_other }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1 or /items/1.json
  def destroy
    @item.destroy!

    respond_to do |format|
      format.html { redirect_to items_path, notice: "Item eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def search_sat_products
    q = params[:q].to_s.strip
    results = SatProduct.where("sku ILIKE :q OR name ILIKE :q", q: "%#{q}%")
                        .order(:sku)
                        .limit(15)
                        .map { |p| { id: p.id, label: "#{p.sku} – #{p.name}" } }
    render json: results
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.expect(item: [ :name, :bar_code, :brand_id, :brand_name, :quantity, :cate, :cost, :desc, :garantia, :offer, :price, :price2, :price3, :sat_product_id, :sku, :status, :stock, :alerta_stock, :unidad, :com_vendedor, :img1, :img2, :img3, :img4, :img5 ])
    end

    def validate_corp
      if @item.corp_id != @corp.id
        redirect_to items_path, alert: "El item que intentas editar no fue encontrado."
      end
    end

    def validate_item
      if @item.corp_id != @corp.id
        redirect_to items_path, alert: "El item que intentas editar no fue encontrado."
      end
    end
end
