class UserPanel::PurchasesController < UserPanelController
  before_action :check_plan
  before_action :set_purchase, only: %i[ show cancel ]
  def index
    purchases = @corp.purchases.default_index

    @q = purchases.ransack(params[:q])
    @pagy, @purchases = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
  end

  def new

    if !@comprita
      @comprita = Purchase.create!(corp: @corp, tipo: :compra)
      session[:comprita_id] = @comprita.id
    elsif !@comprita.carrito?
      @comprita = Purchase.create!(corp: @corp, tipo: :compra)
      session[:comprita_id] = @comprita.id
    end

    @brands = @corp.brands.default
    items = @corp.items.available.includes(
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

  def new_gasto
    if !@gasto
      @gasto = Purchase.create!(corp: @corp, tipo: :gasto)
      session[:gasto_id] = @gasto.id
    elsif !@gasto.carrito?
      @gasto = Purchase.create!(corp: @corp, tipo: :gasto)
      session[:gasto_id] = @gasto.id
    end
  end

  def create_gasto
    @purchase = @corp.purchases.find_by(folio: params[:purchase][:folio])
    return redirect_to user_panel_landing_purchases_path, alert: "Gasto no encontrado" unless @purchase

    @purchase.assign_attributes(gasto_params)

    if @purchase.purchase_items.empty?
      return redirect_to new_gasto_purchases_path, alert: "El gasto no tiene conceptos"
    end

    @purchase.created_at = Time.current
    unless params[:purchase][:fecha].present?
      @purchase.fecha = @purchase.created_at
    end

    @purchase.user = current_user
    @purchase.status = :remision
    @purchase.forma_pago = "por_definir" if @purchase.credito?

    if @purchase.save!
      if @purchase.pagado?
        @purchase.deposits.create!(monto: @purchase.total, forma_pago: @purchase.forma_pago, tipo: :egreso, created_at: @purchase.fecha)
      end
      session[:gasto_id] = nil
      redirect_to purchase_path(@purchase), notice: "Gasto registrado"
    else
      redirect_to new_gasto_purchases_path, alert: @purchase.errors.full_messages.join(", ")
    end
  end

  def create
    @purchase = @corp.purchases.find_by(folio: params[:purchase][:folio])
    return redirect_to user_panel_landing_purchases_path, alert: "Compra no encontrada" unless @purchase

    @purchase.assign_attributes(purchase_params)

    ## validaciones
    if @purchase.purchase_items.empty?
      return redirect_to user_panel_landing_purchases_path, alert: "La compra no tiene productos"
    end

    @purchase.created_at = Time.current
    unless params[:purchase][:fecha].present?
      @purchase.fecha = @purchase.created_at
    end

    @purchase.user = current_user
    @purchase.status = :remision

    @purchase.forma_pago = "por_definir" if @purchase.credito?

    if @purchase.save!

      if @purchase.compra?
        ## aumentamos inventario y actualizamos costo de los productos
        @purchase.purchase_items.each do |line|
          if line.item and !line.item.stock.nil?
            item = line.item
            item.stock += line.cantidad
            item.cost = line.precio
            item.save(validate: false)
          end
        end
      end

      if @purchase.pagado?
        @purchase.deposits.create!(monto: @purchase.total, forma_pago: @purchase.forma_pago, tipo: :egreso, created_at: @purchase.fecha)
      end
      session[:comprita_id] = nil
      redirect_to purchase_path(@purchase), notice: "Compra finalizada"
    else
      redirect_to user_panel_landing_purchases_path, alert: @purchase.errors.full_messages.join(", ")
    end
  end

  def compra_resumen
    @purchase = @corp.purchases.find(params[:id])
  end

  def cancel
    return redirect_to orders_path, alert: "La compra ya está cancelada." if @purchase.cancelado?


    @purchase.status = :cancelado
    @purchase.deposits.destroy_all

    if @purchase.compra?
      ## regresamos inventario
      @purchase.purchase_items.each do |line|
        if line.item and !line.item.stock.nil?
          item = line.item
          item.stock -= line.cantidad
          item.save(validate: false)
        end
      end
      @purchase.error = "Compra cancelada por el usuario #{current_user.email} con fecha #{Time.current.in_time_zone("America/Mexico_City").strftime("%d/%m/%Y %I:%M %p")}."
    end

    @purchase.save
    redirect_back(fallback_location: purchases_path, alert: "Compra cancelada.")
  end

  private

  def set_purchase
    @purchase = @corp.purchases.find(params[:id])
  end

  def check_plan
    unless @corp.plus? or @corp.premium?
      redirect_to user_panel_landing_path, alert: "Esta funcionalidad no está disponible en tu plan actual."
    end
  end

  def purchase_params
    params.expect(purchase: [
      :provider_id,
      :fecha,
      :status,
      :status_pago,
      :forma_pago,
      :deadline,
      :nota_customer
    ])
  end

  def gasto_params
    params.expect(purchase: [
      :provider_id,
      :fecha,
      :status_pago,
      :forma_pago,
      :deadline,
      :nota_customer
    ])
  end
end
