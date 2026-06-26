class Admin::BillsController < AdminController
  before_action :set_bill, only: %i[show timbra marcar_depositado_corp marcar_error_corp]
  def index
    bills = Bill.default.includes(:corp)
    @bills_pagadas = bills.pagado
    @bills_pagadas_a_cliente = bills.where(direccion: :egreso, status_pago: :depositado)
    @retiros_pendientes = bills.where(status_pago: :pendiente, direccion: :egreso)

    @q = bills.ransack(params[:q])
    @pagy, @bills = pagy(@q.result(distinct: true), limit: 20)

    @result = @q.result
  end

  def show
    @corp = @bill.corp || nil
    respond_to do |format|
      format.html
      format.pdf do
        pdf = BillPdf.new(@bill)
        send_data pdf.render, filename: "#{@bill.folio}.pdf", type: "application/pdf", disposition: "inline"
      end
      format.xml do
        if @bill.xml.present?
          send_data @bill.xml, filename: "#{@bill.folio}.xml", type: "application/xml", disposition: "attachment"
        else
          redirect_back fallback_location: user_panel_bills_path, alert: "No se encontró el XML para esta factura."
        end
      end
    end
  end

  def timbra
    ## validaciones
    return redirect_back fallback_location: user_panel_bills_path, alert: "Esta factura ya ha sido timbrada." if @bill.timbre?

    return redirect_back fallback_location: user_panel_bills_path, alert: "Datos SAT incompletos." if !@bill.me_pueden_facturar?
    return redirect_back fallback_location: user_panel_bills_path, alert: "Uso de CFDI requerido" if params[:uso_cfdi].blank?

    @bill.uso_cfdi = params[:uso_cfdi]

    response = Ftools.timbra_bill(@bill, @bill.uso_cfdi)

    if response
      redirect_back fallback_location: user_panel_bills_path, notice: "Factura timbrada exitosamente."
    else
      redirect_back fallback_location: user_panel_bills_path, alert: "Error al timbrar la factura."
    end
  end

  def marcar_depositado_corp
    if @bill.depositado?
      redirect_back fallback_location: admin_bills_path, alert: "Esta factura ya ha sido marcada como depositada."
    else
      @bill.update(
        status_pago: :depositado,
        nota_for_corp: params[:nota_for_corp],
        nota_interna: params[:nota_interna]
      )
      BillMailer.with(bill: @bill, email: @bill.corp.email || @bill.corp.prop.email, time: Time.current).retiro_success.deliver_later
      redirect_back fallback_location: admin_bills_path, notice: "Factura marcada como depositada exitosamente."
    end
  end

  def marcar_error_corp
    if @bill.error_pago? or @bill.depositado?
      redirect_back fallback_location: admin_bills_path, alert: "Esta factura ya ha sido marcada como pagada o con error."
    else
      @bill.update(
        status_pago: :error_pago,
        nota_for_corp: params[:nota_for_corp],
        nota_interna: params[:nota_interna]
      )
      # devolvemos status_pago: :pagado a los deposits involucrados
      deposits_involved = @bill.retiro_deposits.split(",").map(&:to_i)
      @bill.corp.deposits.where(id: deposits_involved).each do |deposit|
        deposit.update(status_pago: :pagado)
      end
      BillMailer.with(bill: @bill, email: @bill.corp.email || @bill.corp.prop.email, time: Time.current).retiro_error.deliver_later
      redirect_back fallback_location: admin_bills_path, notice: "Factura marcada como con error"
    end
  end


  private

  def set_bill
    @bill = Bill.find(params[:id])
  end
end