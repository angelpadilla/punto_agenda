class DepositsPdf < Prawn::Document
  def initialize(deposits:, inicio:, fin:)
    super(top_margin: 20)
    @deposits = deposits
    @ingresos = @deposits.where(tipo: :ingreso).sum(:monto)
    @egresos = @deposits.where(tipo: :egreso).sum(:monto)
    @inicio = inicio
    @fin = fin
    header
    table_content
  end

  def header
    text "Resultado corte", size: 20, style: :bold
    move_down 20
    bounding_box([ bounds.left, cursor ], width: bounds.width, height: 70) do
      stroke_bounds
      text_box "<strong># Movimientos</strong>: #{@deposits.count}", at: [ 5, 65 ], inline_format: true, size: 9
      text_box "<strong>Fecha inicial</strong>: #{@inicio.strftime("%d/%m/%Y")}", at: [ 5, 50 ], inline_format: true, size: 9
      text_box "<strong>Fecha final</strong>: #{@fin.strftime("%d/%m/%Y")}", at: [ 5, 35 ], inline_format: true, size: 9
      text_box "<strong>Ingresos (ventas)</strong>: #{number_to_currency(@ingresos)}", at: [ bounds.width/2, 65 ], inline_format: true
      text_box "<strong>Egresos (gastos)</strong>: #{number_to_currency(@egresos)}", at: [ bounds.width/2, 50 ], inline_format: true
    end
    move_down 10
  end

  def table_content
    table(items_rows) do
      self.header = true
      row(0).font_style = :bold
      self.cell_style = { size: 7, borders: [], padding: 3 }
      self.row_colors = [ "DDDDDD", "FFFFFF" ]
      self.width = 540
    end
  end

  def items_rows
    header = [ [ "ID", "Fecha", "Numero de Operacion", "Forma de Pago", "Objeto", "Objeto ID", "Tipo", "Monto" ] ]
    data = @deposits.map do |deposit|
      [
        deposit.id,
        deposit.created_at.strftime("%d/%m/%Y %I:%M %p"),
        deposit.num_operacion,
        deposit.forma_pago&.titleize,
        deposit.depositable_type == "Order" ? "Venta" : "Compra",
        deposit.depositable_id,
        deposit.tipo.titleize,
        number_to_currency(deposit.monto)
      ]
    end
    header + data
  end

  private

  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end
end
