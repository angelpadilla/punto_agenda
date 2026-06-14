class Admin::SatProductsController < AdminController
  before_action :set_sat_product, only: %i[show edit update destroy]
  before_action :stop_corp_basico

  def index
    sat_products = SatProduct.default

    @q = sat_products.ransack(params[:q])
    @pagy, @sat_products = pagy(@q.result(distinct: true), limit: 20)
  end

  def show; end

  def new
    @sat_product = SatProduct.new
  end

  def edit; end

  def create
    @sat_product = SatProduct.new(sat_product_params)

    if @sat_product.save
      redirect_to admin_sat_product_path(@sat_product), notice: "Producto SAT creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @sat_product.update(sat_product_params)
      redirect_to admin_sat_product_path(@sat_product), notice: "Producto SAT actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sat_product.destroy
    redirect_to admin_sat_products_path, notice: "Producto SAT eliminado exitosamente."
  end

  private

  def set_sat_product
    @sat_product = SatProduct.find(params[:id])
  end

  def sat_product_params
    params.require(:sat_product).permit(:name, :sku)
  end
end
