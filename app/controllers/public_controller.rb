class PublicController < ApplicationController
  before_action :find_corp_by_sku, only: [:show_corp, :show_corp_calendar, :show_corp_menu, :book_event]

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

  def ticket_xml
    @order = Order.find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order
    send_data @order.xml, filename: "venta_#{@order.folio}.xml", disposition: "attachment"
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

  # --- Páginas públicas de empresa ---

  def show_corp
    redirect_to root_path, alert: "Empresa no encontrada" and return unless @corp
  end

  def show_corp_calendar
    redirect_to root_path, alert: "Empresa no encontrada" and return unless @corp
    redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" and return unless @corp.public_calendar?
    @items = @corp.items.servicio.activo
    @available_slots = generate_available_slots
  end

  def show_corp_menu
    redirect_to root_path, alert: "Empresa no encontrada" and return unless @corp
    redirect_to corp_home_path(@corp.sku), alert: "El catálogo no está disponible" and return unless @corp.public_site?
    @cate_filter = params[:cate]
    @items = @corp.items.activo.includes(:brand).order(:cate, :name)
    @items = @items.where(cate: @cate_filter) if @cate_filter.present?
  end

  def book_event
    redirect_to root_path, alert: "Empresa no encontrada" and return unless @corp
    redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" and return unless @corp.public_calendar?

    slot = Time.zone.parse(params[:slot].to_s) rescue nil
    unless slot
      redirect_to corp_calendar_path(@corp.sku), alert: "Selecciona un horario válido" and return
    end

    customer = Customer.find_by(email: params[:email].to_s.strip.downcase)
    if customer.nil?
      customer = Customer.new(
        email:      params[:email].to_s.strip.downcase,
        razon:      params[:nombre].to_s.strip,
        tel:        params[:tel].to_s.strip,
        tel_prefix: params[:tel_prefix].presence || "+52",
        canal:      :web,
        password:   SecureRandom.hex(10)
      )
      unless customer.save
        redirect_to corp_calendar_path(@corp.sku), alert: customer.errors.full_messages.first and return
      end
    end

    CorpCustomer.find_or_create_by(corp: @corp, customer: customer)

    user = @corp.users.first
    unless user
      redirect_to corp_calendar_path(@corp.sku), alert: "No hay agentes disponibles en este momento" and return
    end

    hora_inicio = slot
    hora_final  = slot + @corp.slot_duration.minutes

    event = Event.new(
      corp:        @corp,
      customer:    customer,
      user:        user,
      title:       params[:servicio].presence || "Cita web",
      body:        params[:notas],
      hora_inicio: hora_inicio,
      hora_final:  hora_final,
      canal:       :web
    )

    if event.save
      redirect_to corp_home_path(@corp.sku), notice: "¡Cita agendada! Te contactaremos para confirmar."
    else
      redirect_to corp_calendar_path(@corp.sku), alert: event.errors.full_messages.join(", ")
    end
  end

  private

  def find_corp_by_sku
    @corp = Corp.find_by(sku: params[:sku])
  end

  def generate_available_slots
    return [] unless @corp.business_hours.present? && @corp.slot_duration.to_i > 0

    booked = @corp.events
                  .where(status: [ :agendado, :completado ])
                  .where(hora_inicio: Time.zone.now.beginning_of_day...(Time.zone.today + 14).end_of_day)
                  .pluck(:hora_inicio, :hora_final)

    slots = []
    (Date.today..(Date.today + 13)).each do |date|
      day_config = @corp.business_hours[date.wday.to_s]
      next unless day_config&.dig("active")

      (day_config["hours"] || []).each do |range|
        open_t  = Time.zone.parse("#{date} #{range['open']}")
        close_t = Time.zone.parse("#{date} #{range['close']}")
        slot = open_t
        while slot + @corp.slot_duration.minutes <= close_t
          next_slot = slot + @corp.slot_duration.minutes
          unless booked.any? { |ini, fin| slot < fin && next_slot > ini }
            slots << slot
          end
          slot = next_slot
        end
      end
    end

    slots
  end
end
