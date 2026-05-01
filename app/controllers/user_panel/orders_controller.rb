class UserPanel::OrdersController < UserPanelController
  before_action :set_order, only: %i[ show edit update destroy ]

  def index
    orders = @corp.orders.not_carritos.includes(:customer)

    @q = orders.ransack(params[:q])
    @pagy, @orders = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
  end

  def new
    if !@carrito
      # Si no hay @carrito, creamos uno nuevo por primera vez aquí en session
      @carrito = Order.create!(user_id: current_user.id, corp_id: @corp.id)
      session[:carrito_id] = @carrito.id
    elsif !@carrito.carrito?
      # Si hay @carrito pero no es de tipo carrito, creamos uno nuevo y actualizamos session
      # puede pasar que en el proceso de :create, no se haya limpiado session[:carrito_id] por alguna razon,
      # entonces este bloque se asegura de que si el carrito en session no es realmente un carrito, se cree uno nuevo
      @carrito = Order.create!(user_id: current_user.id, corp_id: @corp.id)
      session[:carrito_id] = @carrito.id
    end

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
    ## parametros permitidos
    # :customer_id,
    # :fecha,
    # :tipo,
    # :forma_pago,
    # :status_pago
    # :deadline,
    # :uso_cfdi,
    # :seller_id,
    # :nota_customer,
    # :nota_interna,
    @order = @corp.orders.find(params[:id])
    # puts "Creando orden a partir de la orden #{@order.folio}"
    # redirect_back fallback_location: user_panel_home_path, notice: "Orden creada #{@order.folio}"
    @order.assign_attributes(order_params)

    ## valicaciones extras
    if @order.line_items.empty?
      return redirect_back(fallback_location: user_panel_home_path, alert: "La venta no tiene productos")
    end

    @order.forma_pago = "por_definir" if @order.pre_factura?
    @order.created_at = Time.current.in_time_zone("America/Mexico_City")

    unless params[:order][:fecha].present?
      @order.fecha = @order.created_at
    end

    unless params[:order][:seller_id].present?
      @order.seller_id = current_user.id
    end

    if @order.remision_factura?
      ## validamos inventario
      stock_errors = false
      @order.line_items.each do |line|
        item = line.item
        if item.stock < line.cantidad
          line.error = "No hay suficiente inventario para este item. Actualiza la cantidad o elimina el item para continuar."
          line.save
          stock_errors = true
        end
      end

      if stock_errors
        return redirect_back(fallback_location: user_panel_home_path, alert: "No hay suficiente inventario para algunos items. Revisa el resumen del ticket para más detalles.")
      end
    end

    if @order.save
      if !@order.cotizacion?
        # rebajamos inventario
        @order.line_items.each do |line|
          item = line.item
          item.stock -= line.cantidad
          item.save
        end
      end

      if @order.remision_factura?
        if @order.pagado?
          @order.deposits.create!(monto: @order.total, forma_pago: @order.forma_pago, tipo: :ingreso, created_at: @order.created_at)
        end

        if @order.factura?
          if @order.alias.timbres > 0
            response = Atools.timbra_order(@order, @order.uso_cfdi)

            if response
              if @order.customer.email.present?
                OrderMailer.with(order: @order, email: @order.customer.email).send_order.deliver_later
              else
                @order.error = "Comprobante timbrado, pero el comprobante no pudo ser enviado al cliente, no tiene email asignado."
                @order.save
              end
            end
          else
            @order.tipo = "remision"
            @order.error = "No hay timbres disponibles para timbrar"
            @order.save
          end
        end
      end


      session[:carrito_id] = nil

      redirect_to order_path(@order), notice: "Venta creada exitosamente"
    else
      redirect_back fallback_location: user_panel_home_path, alert: @order.errors.full_messages.join(", ")
    end

    # respond_to do |format|
    #   if @order.save
    #     format.html { redirect_to user_panel_order_url(@order), notice: "Order was successfully created." }
    #     format.json { render :show, status: :created, location: @order }
    #   else
    #     format.html { render :new, status: :unprocessable_entity }
    #     format.json { render json: @order.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to order_path(@order), notice: "Venta actualizada exitosamente." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @order.destroy

    redirect_to user_panel_orders_url, notice: "Venta eliminada exitosamente."
  end

  private

    def set_order
      @order = @corp.orders.find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :customer_id,
        :fecha,
        :tipo,
        :forma_pago,
        :status_pago,
        :deadline,
        :uso_cfdi,
        :seller_id,
        :nota_customer,
        :nota_interna
      )
    end
end
