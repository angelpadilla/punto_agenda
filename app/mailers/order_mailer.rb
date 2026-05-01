class OrderMailer < ApplicationMailer
  def send_order
    @order = params[:order]
    email = params[:email]

    pdf = OrderPdf.new(order: @order)
    attachments["venta_#{@order.sku}.pdf"] = pdf.render

    if @order.xml.present? and @order.tipo == "factura"
      attachments["venta_#{@order.sku}.xml"] = @order.xml
    end

    mail(to: email, subject: "POSS Venta #{@order.sku}")
  end

  def send_abono
    @deposit = params[:deposit]
    email = params[:email]

    pdf = AbonoPdf.new(deposit: @deposit)
    attachments["abono_#{@deposit.id}.pdf"] = pdf.render

    if @deposit.xml.present? and @deposit.depositable&.tipo == "factura"
      attachments["abono_#{@deposit.id}.xml"] = @deposit.xml
    end

    mail(to: email, subject: "POSS Abono #{@deposit.id}")
  end
end
