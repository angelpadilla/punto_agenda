class PublicController < ApplicationController
  def home
    @stripe_token = Rails.application.credentials.dig(:stripe_token)
    @awstoken = Rails.application.credentials.dig(:aws, :token1)
  end

  def html_elements
  end

  def ticket80
    @order = Order.includes(:customer, :line_items, :corp).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order

    pdf = Order80Pdf.new(order: @order)
    send_data pdf.render, filename: "venta_#{@order.folio}.pdf", type: "application/pdf", disposition: "inline"
  end
  
  def ticket
    @order = Order.includes(:customer, :line_items, :corp).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order

    pdf = OrderPdf.new(order: @order)
    send_data pdf.render, filename: "venta_#{@order.folio}.pdf", type: "application/pdf", disposition: "inline"
  end

  def pdf_abono
    @deposit = Deposit.includes(:depositable).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit

    pdf = AbonoPdf.new(deposit: @deposit)
    send_data pdf.render, filename: "abono_#{@deposit.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  def ticket_abono
    @deposit = Deposit.includes(:depositable).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit
    pdf = Abono80Pdf.new(deposit: @deposit)
    send_data pdf.render, filename: "abono_#{@deposit.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  def abono_xml
    @deposit = Deposit.find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit
    send_data @deposit.xml, filename: "abono_#{@deposit.id}.xml", disposition: "attachment"
  end
end
