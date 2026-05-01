class ReporteVentasPdf < Prawn::Document
  def initialize(orders:, fecha_inicial:, fecha_final:)
    super(top_margin: 20)
    @setting = Setting.first
    @orders = orders
    @fecha_inicial = fecha_inicial
    @fecha_final = fecha_final

    @costos = orders.sum(:costo)
    @comisiones_terminal = orders.sum(:comision_terminal)
    @utilidad = orders.sum(:ganancia)
    @total = orders.sum(:total)
    @fontsize = 10
    font_size @fontsize
    header
    table_content
  end

  def header
    if @setting.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@setting.logo.key)
      image(logo_path, width: 100)
      move_down 10
    end
    text "Reporte de ventas", size: 20, style: :bold
    move_down 20
    text "<strong>Desde:</strong> #{@fecha_inicial.strftime("%d/%m/%Y")}", size: @fontsize, inline_format: true
    text "<strong>Hasta:</strong> #{@fecha_final.strftime("%d/%m/%Y")}", size: @fontsize, inline_format: true
    text "<strong># Ventas:</strong> #{@orders.count}", size: @fontsize, inline_format: true
  end

  def table_content
    move_down 10
    fontsize = @fontsize - 1
    table items_rows do
      self.header = true
      row(0).font_style = :bold
      row(1).font_style = :bold
      self.row_colors = [ "DDDDDD", "FFFFFF" ]
      self.cell_style = { size: fontsize, padding: 3 }
      self.width = 540
    end
  end
  def items_rows
    header = [ [ "Folio", "Fecha", "Cliente", "Tipo", "Estatus", "Monto", "Costo", "Comision terminal", "Utilidad" ] ]
    data = @orders.map do |order|
      [
        order.sku,
        order.fecha.strftime("%d/%m/%Y"),
        order.customer ? order.customer.razon : "Cliente no asignado o eliminado de sistema",
        order.tipo&.titleize,
        order.status&.titleize,
        number_to_currency(order.total, precision: 4),
        number_to_currency(order.costo, precision: 4),
        number_to_currency(order.comision_terminal, precision: 4),
        number_to_currency(order.ganancia, precision: 4)
      ]
    end
    total_row = [
      { content: "Totales", colspan: 5, align: :right },
      number_to_currency(@total),
      number_to_currency(@costos),
      number_to_currency(@comisiones_terminal),
      number_to_currency(@utilidad)
    ]
    # header + data + [ total_row ]
    [ total_row ] + header  + data
  end

  private

  def number_to_currency(number, precision: 2)
    ActionController::Base.helpers.number_to_currency(number, precision: precision)
  end
end
