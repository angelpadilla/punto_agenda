class UserPanelController < ApplicationController
  layout "user"
  before_action :authenticate_user!
  before_action :set_globals
  before_action :authorize_corp!, except: [ :home ]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def home
    if @corp.active
      today          = Date.today
      start_of_today = today.beginning_of_day
      end_of_today   = today.end_of_day
      month_start    = today.beginning_of_month.beginning_of_day
      prev_month_start = (today - 1.month).beginning_of_month.beginning_of_day
      prev_month_end   = (today - 1.month).end_of_month.end_of_day

      # ── Tab: Hoy ─────────────────────────────────────────────────────
      orders_today      = @corp.orders.not_carritos.where(created_at: start_of_today..end_of_today)
      @orders_hoy_count = orders_today.count
      @venta_bruta_hoy  = orders_today.where.not(status_pago: :cancelado).sum(:total)

      @proximos_eventos = @corp.events
                              .where(hora_inicio: start_of_today..end_of_today)
                              .where("hora_inicio >= ?", Time.current)
                              .order(hora_inicio: :asc)
                              .includes(:customer, :user)
                              .limit(8)

      @slots_info = slots_today_info(today) if @corp.calendar

      # ── Tab: Ventas ───────────────────────────────────────────────────
      dias = %w[Dom Lun Mar Mié Jue Vie Sáb]
      @ventas_semana = (6.days.ago.to_date..today).map do |date|
        {
          label: "#{dias[date.wday]} #{date.day}",
          total: @corp.orders.not_carritos.pagados
                      .where(created_at: date.beginning_of_day..date.end_of_day)
                      .sum(:total).to_f
        }
      end

      mes_orders = @corp.orders.not_carritos.where(created_at: month_start..end_of_today)
      prev_mes_orders = @corp.orders.not_carritos.where(created_at: prev_month_start..prev_month_end)

      @venta_mes      = mes_orders.where.not(status_pago: :cancelado).sum(:total)
      @venta_mes_prev = prev_mes_orders.where.not(status_pago: :cancelado).sum(:total)
      @venta_mes_pct  = @venta_mes_prev > 0 ? ((@venta_mes - @venta_mes_prev) / @venta_mes_prev * 100).round(1) : nil

      @margen_mes     = mes_orders.where.not(status_pago: :cancelado).sum(:ganancia)
      @ticket_promedio = @orders_hoy_count > 0 ? (@venta_bruta_hoy / @orders_hoy_count) : 0

      @cuentas_por_cobrar = @corp.orders.not_carritos.creditos.sum(:debe)

      # Venta por tipo (donut)
      @venta_por_tipo = Order.tipos.keys.reject { |t| t == "carrito" }.filter_map do |tipo|
        total = @corp.orders.where(tipo: tipo)
                    .where(created_at: month_start..end_of_today)
                    .where.not(status_pago: :cancelado)
                    .sum(:total).to_f
        { label: tipo.titleize, value: total } if total > 0
      end

      # Venta por forma de pago (donut) — desde deposits del mes
      @venta_por_pago = @corp.orders.not_carritos
                            .where(created_at: month_start..end_of_today)
                            .where.not(status_pago: :cancelado)
                            .reorder(nil)
                            .group(:forma_pago)
                            .sum(:total)
                            .filter_map do |fp, total|
                              next if total <= 0
                              label = Order.forma_pagos.key(fp)&.humanize&.titleize || fp || "N/D"
                              { label: label, value: total.to_f }
                            end

      @ordenes_recientes = @corp.orders.not_carritos.includes(:customer).limit(6)

      # ── Tab: Clientes ─────────────────────────────────────────────────
      @nuevos_clientes_mes  = @corp.customers.where(created_at: month_start..end_of_today).count
      @top_clientes         = @corp.customers.where("total_spent > 0")
                                  .order(total_spent: :desc).limit(8)
      @clientes_con_deuda   = @corp.orders.not_carritos.creditos
                                  .where("debe > 0")
                                  .includes(:customer)
                                  .order(debe: :desc)
                                  .limit(6)

      # ── Tab: Agenda ───────────────────────────────────────────────────
      if @corp.calendar
        @eventos_completados_mes = @corp.events.completado
                                        .where(hora_inicio: month_start..end_of_today).count
        eventos_mes_total = @corp.events.where(hora_inicio: month_start..end_of_today)
                                .where.not(status: :cancelado).count
        @tasa_asistencia = eventos_mes_total > 0 ?
          (@eventos_completados_mes * 100.0 / eventos_mes_total).round(1) : nil

        # Eventos por agente (barras horizontales)
        @eventos_por_agente = @corp.users.actives.map do |u|
          completados = u.events.completado
                        .where(hora_inicio: month_start..end_of_today)
                        .where(corp_id: @corp.id).count
          { label: u.full_name&.titleize || u.email, value: completados }
        end.select { |e| e[:value] > 0 }.sort_by { |e| -e[:value] }.first(6)

        # Clientes con inasistencias
        @clientes_riesgo = @corp.customers.where("failed_events > 0")
                                .order(failed_events: :desc).limit(5)
      end

      # ── Tab: Inventario ───────────────────────────────────────────────
      @alertas_inventario = @corp.items
                                .where.not(alerta_stock: nil)
                                .where("stock <= alerta_stock AND status != 2")
                                .order(:stock)
                                .limit(10)

      @valor_inventario = @corp.items.where.not(status: :inactivo)
                              .where("cost IS NOT NULL AND stock IS NOT NULL")
                              .sum("stock * cost")

      @item_estrella = @corp.items.where("orders_count > 0")
                          .order(orders_count: :desc).first

      @items_sin_movimiento = @corp.items.where(orders_count: 0)
                                  .where.not(status: :inactivo).count

      @top_items = @corp.items.where("orders_count > 0")
                      .order(orders_count: :desc).limit(6)

      # Inventario por categoría (donut)
      @inv_por_cate = Item.cates.keys.filter_map do |cate|
        count = @corp.items.where(cate: cate).where.not(status: :inactivo).count
        { label: cate.titleize, value: count } if count > 0
      end
    end
  end

  def landing_purchases
  end

  def landing_orders
  end

  def record_not_found
    redirect_to user_panel_home_path, alert: "Ups, Objeto no fue encontrado."
  end

  private

  def set_globals
    @user = current_user
    @corp = @user.corp

    if session[:carrito_id]
      @carrito = Order.find_by(id: session[:carrito_id])
    end
  end

  def slots_today_info(date)
    bh = @corp.business_hours
    return nil if bh.blank?

    cfg = bh[date.wday.to_s]
    return nil unless cfg && ActiveModel::Type::Boolean.new.cast(cfg["active"])

    open_h,  open_m  = cfg["open"].split(":").map(&:to_i)
    close_h, close_m = cfg["close"].split(":").map(&:to_i)
    step = @corp.slot_duration || 15

    total_min = close_h * 60 + close_m - (open_h * 60 + open_m)
    total     = (total_min.to_f / step).floor
    return nil if total <= 0

    booked = @corp.events
                  .where(hora_inicio: date.beginning_of_day..date.end_of_day)
                  .where.not(status: :cancelado)
                  .count

    occupied  = [ booked, total ].min
    available = [ total - occupied, 0 ].max
    pct       = (occupied * 100.0 / total).round

    { total: total, disponibles: available, ocupados: occupied, pct: pct,
      open: cfg["open"], close: cfg["close"] }
  end

  def authorize_corp!
    unless current_user.corp.active
      redirect_to user_panel_home_path, alert: "Tu cuenta no está activa. Contacta al administrador."
    end
  end
end
