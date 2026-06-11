class PublicController < ApplicationController
  before_action :find_corp_by_sku, only: [ :show_corp, :show_corp_calendar, :show_corp_menu, :book_event ]

  def home
    @last_articles = Post.default.limit(6)
  end

  def index_blog
    posts = Post.default

    @q = posts.ransack(params[:q])
    @pagy, @posts = pagy(@q.result(distinct: true), limit: 6)
  end

  def show_blog
    @post = Post.find_by(slug: params[:slug])
    redirect_to index_blog_path, alert: "Artículo no encontrado" unless @post
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
    redirect_to root_path, alert: "Empresa no encontrada" unless @corp
  end

  def show_corp_calendar
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" unless @corp.public_calendar?
    @items = @corp.items.servicio.activo
    @available_slots = generate_available_slots
  end

  def show_corp_menu
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El catálogo no está disponible" unless @corp.public_site?
    @cate_filter = params[:cate]
    @items = @corp.items.activo.includes(:brand).order(:cate, :name)
    @items = @items.where(cate: @cate_filter) if @cate_filter.present?
  end

  def book_event
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" unless @corp.public_calendar?

    slot = Time.zone.parse(params[:slot].to_s) rescue nil
    unless slot
      return redirect_to corp_calendar_path(@corp.sku), alert: "Selecciona un horario válido"
    end

    customer = Customer.find_by(email: params[:email].to_s.strip.downcase)
    if customer.nil?
      token = Generatepass.gen(exclude_ambiguous: true, include_symbols: false, length: 8)
      customer = Customer.new(
        email:      params[:email].to_s.strip.downcase,
        razon:      params[:nombre].to_s.strip,
        tel:        params[:tel].to_s.strip,
        tel_prefix: params[:tel_prefix].presence || "+52",
        canal:      :web,
        password:   token,
        password_confirmation: token,
        passs: token
      )
      unless customer.save
        return redirect_to corp_calendar_path(@corp.sku), alert: customer.errors.full_messages.first
      end
    end

    CorpCustomer.find_or_create_by(corp: @corp, customer: customer)

    user = @corp.users.first
    unless user
      return redirect_to corp_calendar_path(@corp.sku), alert: "No hay agentes disponibles en este momento"
    end

    hora_inicio = slot
    day_config  = @corp.business_hours[slot.wday.to_s]
    slot_range  = (day_config&.dig("hours") || []).find { |r| Time.zone.parse("#{slot.to_date} #{r['open']}") == slot }
    hora_final  = slot_range ? Time.zone.parse("#{slot.to_date} #{slot_range['close']}") : slot + 60.minutes

    event = Event.new(
      corp:        @corp,
      customer:    customer,
      user:        user,
      title:       params[:servicio].presence || "Cita web",
      body:        params[:notas],
      hora_inicio: hora_inicio,
      hora_final:  hora_final,
      canal:       :web,
      status:      :por_confirmar
    )

    if event.save
      EventMailer.with(corp: @corp, event: event).noti_corp.deliver_later
      redirect_to corp_home_path(@corp.sku), notice: "¡Cita agendada! Por favor espera la confirmacion al email que proporcionaste."
    else
      redirect_to corp_calendar_path(@corp.sku), alert: event.errors.full_messages.join(", ")
    end
  end

  private

  def find_corp_by_sku
    @corp = Corp.find_by(sku: params[:sku])
  end

  def generate_available_slots
    return [] unless @corp.business_hours.present?

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
        unless booked.any? { |ini, fin| open_t < fin && close_t > ini }
          slots << open_t
        end
      end
    end

    slots
  end
end
