class PublicController < ApplicationController
  def home
    @stripe_token = Rails.application.credentials.dig(:stripe_token)
    @awstoken = Rails.application.credentials.dig(:aws, :token1)
  end

  def html_elements
  end

  def ticket80
    @order = Order.includes(:customer, :line_items).find_by(folio: params[:folio])

    redirect_to root_path, alert: "Order not found" if !@order

    pdf = Order80Pdf.new(order: @order)
    send_data pdf.render, filename: "venta_#{@order.folio}.pdf", type: "application/pdf", disposition: "inline"
  end
end
