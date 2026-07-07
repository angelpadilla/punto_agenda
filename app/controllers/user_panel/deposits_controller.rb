class UserPanel::DepositsController < UserPanelController
  before_action :set_deposit, only: %i[ show destroy ]

  # GET /deposits or /deposits.json
  def index
    deposits = @corp.deposits.default

    # Adjust created_at_gteq and created_at_lteq to search from the beginning to the end of the day
    if params[:q] && params[:q][:created_at_gteq].present?
      params[:q][:created_at_gteq] = params[:q][:created_at_gteq].to_date.beginning_of_day
    end

    if params[:q] && params[:q][:created_at_lteq].present?
      params[:q][:created_at_lteq] = params[:q][:created_at_lteq].to_date.end_of_day
      @fin = params[:q][:created_at_lteq]
    else
      @fin = Time.current.end_of_day
    end

    @q = deposits.ransack(params[:q])
    @resultados = @q.result.preload(:depositable)

    @pagy, @deposits = pagy(@resultados, limit: 25)

    respond_to do |format|
      format.html
      format.pdf {
        pdf = DepositsPdf.new(deposits: @resultados, inicio: params[:q][:created_at_gteq], fin: @fin)
        send_data pdf.render, filename: "deposits_#{Time.current.to_i}.pdf", type: "application/pdf", disposition: "inline"
      }
    end
  end

  # GET /deposits/1 or /deposits/1.json
  def show
  end

  # GET /deposits/new
  def new
    @deposit = @corp.deposits.new
  end

  def create_for_purchase
    purchase = @corp.purchases.find(params[:purchase_id])
    monto = params[:monto].to_f

    return redirect_back(fallback_location: user_panel_home_path, alert: "El monto abonado no puede ser mayor al monto que se debe") if monto > purchase.debe

    @deposit = purchase.deposits.new(
      monto: monto,
      forma_pago: params[:forma_pago],
      tipo: :egreso,
      created_at: params[:created_at],
      num_operacion: params[:num_operacion],
    )

    if @deposit.save
      purchase.status_pago = "pagado" if purchase.deposits.sum(:monto) >= purchase.total
      purchase.save
      redirect_to purchase_path(purchase), notice: "Deposito añadido"
    else
      purchase.update(error: @deposit.errors.messages)
      redirect_to purchase_path(purchase), alert: @deposit.errors.messages
    end
  end

  # POST /deposits or /deposits.json
  def create
    order = @corp.orders.find(params[:order_id])
    monto = params[:monto].to_f

    return redirect_back(fallback_location: user_panel_home_path, alert: "El monto abonado no puede ser mayor al monto que se debe") if monto > order.debe

    @deposit = order.deposits.new(
      monto: monto,
      forma_pago: params[:forma_pago],
      moneda: "MXN",
      tipo: :ingreso,
      created_at: params[:created_at],
      num_operacion: params[:num_operacion],
    )

    # if params[:forma_pago] == "04"
    #   return redirect_back(fallback_location: user_panel_home_path, alert: "Debe seleccionar una forma de pago para tarjeta de credito") unless params[:forma_credito].present?
    #   if params[:forma_credito] == "1"
    #     comision_terminal = monto - (monto / 1.03)
    #   elsif params[:forma_credito] == "2"
    #     comision_terminal = monto - (monto / 1.11)
    #   else
    #     comision_terminal = monto - (monto / 1.17)
    #   end
    # elsif params[:forma_pago] == "28"
    #   comision_terminal = monto - (monto / 1.03)
    # else
    #   comision_terminal = 0.0
    # end
    # @deposit.comision_terminal = comision_terminal

    if @deposit.save
      if order.tipo == "factura"
        if !order.sat_uuid.present?
          @deposit.destroy
          order.error = "Error: La factura no tiene UUID (no ha sido timbrada). No se puede timbrar el complemento de pago sin el UUID de la factura original."
          order.tipo = "remision"
          order.save
          return redirect_back(fallback_location: user_panel_home_path, alert: order.error)
        elsif order.alias.timbres > 0
          response = Ftools.timbra_deposito(order, @deposit)

          if response
            if order.customer.email2.present?
              OrderMailer.with(deposit: @deposit, email: order.customer.email2).send_abono.deliver_later
            else
              order.error = "Comprobante de pago timbrado, pero el comprobante no pudo ser enviado al cliente, no tiene email asignado."
            end
          end
        else
          order.error = "No hay timbres disponibles para timbrar el abono"
          order.save
          @deposit.destroy
          return redirect_back(fallback_location: user_panel_home_path, alert: order.error)
        end
      end
      order.status_pago = "pagado" if order.deposits.sum(:monto) >= order.total
      order.save
      redirect_to order_path(order), notice: "Deposito añadido"
    else
      order.update(error: @deposit.errors.messages)
      redirect_to order_path(order), alert: @deposit.errors.messages
    end
  end


  # DELETE /deposits/1 or /deposits/1.json
  def destroy
    if @deposit.depositable_type == "Order"
      order = @deposit.depositable
      if order.tipo == "factura" and @deposit.sat_uuid.present?
        response = Ftools.cancela_deposito(order, @deposit)
        unless response
          redirect_back(fallback_location: user_panel_home_path, alert: "Error al eliminar deposito")
        end
      end

      @deposit.destroy
      order.status_pago = "credito" if order.deposits.sum(:monto) < order.total
      order.save

      redirect_back(fallback_location: user_panel_home_path, notice: "Deposito eliminado")
    else
      purchase = @deposit.depositable
      @deposit.destroy

      purchase.status_pago = "credito" if purchase.deposits.sum(:monto) < purchase.total
      purchase.save
      redirect_back(fallback_location: user_panel_home_path, notice: "Deposito eliminado")
    end
  end

  def mod_forma_pago
    @order = @corp.orders.find(params[:order_id])
    @deposit = @corp.deposits.find(params[:deposit_id])
    forma_pago_anterior = @deposit.forma_pago
    forma_pago_nueva = params[:forma_pago]

    ## solo aceptar si la venta es dif a tipo factura
    if @order.tipo != "remision"
      return redirect_to @order, alert: "Solo son permitidas las modificaciones de abonos en remisiones."
    end

    if forma_pago_nueva != forma_pago_anterior
      if @order.por_definir?
        ## venta que fue o es credito
        @deposit.update(forma_pago: forma_pago_nueva)
      else
        ## venta de una sola exhibicion
        @order.forma_pago = forma_pago_nueva
        @deposit.update(forma_pago: forma_pago_nueva)
      end

      if (forma_pago_nueva == "tarjeta_de_credito" or forma_pago_nueva == "tarjeta_de_debito") and !@order.aumentado_comision_terminal
        # vamos a aumentar un porcentaje al total de la venta cuando es forma pago tarjeta de credito o debito
        # el aumento de precio va individual por item en line_items y actualizamos total de la venta
        @order.line_items.each do |line|
          nuevo_precio = line.precio * 1.02
          line.update(precio: nuevo_precio)
        end
        # actualizamos totales de la venta
        @order.aumentado_comision_terminal = true
        @order.status = "credito"
      end

      credito_debito_exists = @order.deposits.where(forma_pago: [ "tarjeta_de_credito", "tarjeta_de_debito" ]).exists?

      if (forma_pago_anterior == "tarjeta_de_credito" or forma_pago_anterior == "tarjeta_de_debito") and (forma_pago_nueva != "tarjeta_de_credito" and forma_pago_nueva != "tarjeta_de_debito") and @order.aumentado_comision_terminal and !credito_debito_exists
        # vamos a reducir el porcentaje al total de la venta cuando se quita la forma pago tarjeta de credito o debito
        # la reduccion de precio va individual por item en line_items
        @order.line_items.each do |line|
          nuevo_precio = line.precio/1.02
          line.update(precio: nuevo_precio)
        end
        # actualizamos totales de la venta
        @order.aumentado_comision_terminal = false
      end

      @order.save

      redirect_to @order, notice: "Forma de pago del abono actualizada."

    else
      redirect_to @order, notice: "La forma de pago es la misma, no se realizaron cambios."
    end
  end

  def send_abono_email
    ## validate id and email present
    if !params[:folio].present? or !params[:email].present?
      return redirect_back(fallback_location: landing_orders_path, alert: "Folio de abono o email no proporcionado")
    end
    deposit = @corp.deposits.find_by(folio: params[:folio])
    email = params[:email]

    OrderMailer.with(deposit: deposit, email: email).send_abono.deliver_later
    redirect_back(fallback_location: order_path(deposit.depositable), notice: "Email del abono enviado a #{email}")
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deposit
      @deposit = @corp.deposits.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def deposit_params
      params.require(:deposit).permit(
        :monto,
        :forma_pago,
        :xml,
        :sat_cfdi,
        :sat_sello,
        :sat_serial,
        :sat_uuid,
        :uso_cfdi,
        :stamp_date,
        :sat_error,
        :moneda,
        :tipo,
        :num_operacion
      )
    end
end
