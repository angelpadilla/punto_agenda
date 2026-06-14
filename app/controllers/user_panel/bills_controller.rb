class UserPanel::BillsController < UserPanelController
  before_action :set_bill, only: %i[ show timbra ]
  def index
    bills = @corp.bills.default

    @q = bills.ransack(params[:q])
    @pagy, @bills = pagy(@q.result(distinct: true), limit: 10)
  end

  def show
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

  private

  def set_bill
    @bill = @corp.bills.find(params[:id])
  end
end
