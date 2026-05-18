class OrderMailer < ApplicationMailer
  def send_order
    @order = params[:order]
    @corp = @order.corp
    email = params[:email]

    pdf = OrderPdf.new(order: @order)
    attachments["venta_#{@order.folio}.pdf"] = pdf.render

    if @order.xml.present? and @order.tipo == "factura"
      attachments["venta_#{@order.folio}.xml"] = @order.xml
    end

    mail(to: email, subject: "#{@corp.name} venta #{@order.folio}")
  end

  def send_abono
    @deposit = params[:deposit]
    @corp = @deposit.corp
    email = params[:email]

    pdf = AbonoPdf.new(deposit: @deposit)
    attachments["abono_#{@deposit.folio}.pdf"] = pdf.render

    if @deposit.xml.present? and @deposit.depositable&.tipo == "factura"
      attachments["abono_#{@deposit.folio}.xml"] = @deposit.xml
    end

    mail(to: email, subject: "#{@corp.name} abono #{@deposit.folio}")
  end
end
