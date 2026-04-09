class UserPanel::OrdersController < UserPanelController
  before_action :set_order, only: %i[ show edit update destroy ]

  def index
    orders = @corp.orders.default

    @q = orders.ransack(params[:q])
    @pagy, @orders = pagy(@q.result(distinct: true), limit: 10)
  end

  def show
  end

  def new

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
    @pagy, @items = pagy(@q.result(distinct: true), limit: 12)
  end

  def edit
  end

  def create
    @order = @corp.orders.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to user_panel_order_url(@order), notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to user_panel_order_url(@order), notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @order.destroy

    redirect_to user_panel_orders_url, notice: "Order was successfully destroyed."
  end

  private

    def set_order
      @order = @corp.orders.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:title, :description, :status, :total_price, :user_id)
    end
end