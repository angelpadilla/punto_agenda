class Abono80Pdf < Prawn::Document
  def initialize(deposit:)
    # Ancho de 80mm en puntos (1mm = 2.83 pt)
    page_width = 72 * 2.8346
    super(page_size: [ page_width, 900 ], margin: [ 0, 5, 0, 0 ])

    @order = deposit.depositable
    @deposit = deposit
    @customer = @order.customer
    @corp = @order.corp
    @fontsize = 9
    font_size @fontsize
    head
    cliente
    body
    factura if @order.tipo == "factura" and @deposit.xml.present?
  end

  def head
    move_down 10
    if @corp.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@corp.logo.key)
      image(logo_path, height: 80, position: :center)
      move_down 10
    end

    text "** Complemento de pago (abono) **", size: (@fontsize + 2), style: :bold, align: :center
    move_down 10
    text "<strong>Folio</strong>: #{@deposit.folio}", inline_format: true, size: (@fontsize + 2)
    text "<strong>Monto pagado</strong>: #{number_to_currency(@deposit.monto)}", inline_format: true, size: (@fontsize + 2)
    text "<strong>Metodo</strong>: #{@deposit.forma_pago&.titleize}", inline_format: true, size: (@fontsize + 2)
    move_down 10
    text "<strong>Fecha</strong>: #{@deposit.created_at.strftime('%d/%m/%Y')}", inline_format: true
    text "<strong>Forma de pago</strong>: #{@deposit.forma_pago&.titleize}", inline_format: true
    if @deposit.xml.present?
      text "<strong>Uso CFDI</strong>: #{@deposit.uso_cfdi}", inline_format: true
    end

    move_down 5
    text "Detalles venta", style: :bold, size: (@fontsize + 1)
    text "<strong>Folio venta</strong>: #{@order.folio}", inline_format: true
    text "<strong>Estatus de venta</strong>: #{@order.status_pago&.titleize}", inline_format: true
    text "<strong>Uso CFDI</strong>: Por definir", inline_format: true
    text "<strong>Forma de pago</strong>: #{@order.forma_pago&.titleize}", inline_format: true
    move_down 10
  end

  def cliente
    move_down 5

    text "Emisor", style: :bold, size: (@fontsize + 1)
    text @corp.razon
    text "<strong>RFC</strong>: #{@corp.rfc}", inline_format: true
    text "<strong>Direccion</strong>: #{@corp.calle.titleize} #{@corp.num_ext} #{@corp.num_int}, #{@corp.colonia}, #{@corp.ciudad}, #{@corp.estado.titleize}", inline_format: true
    text "<strong>Tel</strong>: #{@corp.phone}", inline_format: true
    move_down 5

    text "Receptor (cliente)", style: :bold, size: (@fontsize + 1)

    if @customer
      text "<strong>Razon</strong>: #{@customer.razon}", inline_format: true
      text "<strong>RFC</strong>: #{@customer.rfc}", inline_format: true
      unless @order.cotizacion?
        text "<strong>Estado</strong>: #{@customer.estado}", inline_format: true
        text "<strong>C.P.</strong>: #{@customer.cp}, #{@customer.estado}", inline_format: true
        text "<strong>Ciudad</strong>: #{@customer.ciudad}", inline_format: true
      end
    else
      text "Cliente eliminado de sistema", style: :bold
    end
    move_down 5
    stroke_horizontal_rule
  end

  def body
    move_down 10
    text "Historial de abonos", style: :bold, size: (@fontsize + 1)
    move_down 5

    font_size = @fontsize
    ancho = bounds.width

    saldo_anterior = @order.total

    @order.deposits.each_with_index do |deposit, index|
      num_deposit = "#{(index + 1)}"
      table([
        [ "Num. Parcialidad", "Folio", "Metodo pago" ],
        [ num_deposit, deposit.folio, deposit.forma_pago&.titleize ]
      ], width: bounds.width, column_widths: [ (ancho * 0.35), (ancho * 0.45), (ancho * 0.2) ]) do
        self.cell_style = { borders: [], padding: 1, size: font_size }
        row(0).font_style = :bold
        # row(0).size = font_size - 1
        # columns(1).align = :center
      end
      move_down 5

      table([
        [ "Saldo anterior", "Saldo pagado", "Saldo insoluto" ],
        [ number_to_currency(saldo_anterior), number_to_currency(deposit.monto), number_to_currency(saldo_anterior - deposit.monto) ]
      ], width: bounds.width, column_widths: [ (ancho * 0.33), (ancho * 0.33), (ancho * 0.34) ]) do
        self.cell_style = { borders: [], padding: 0, size: font_size }
        row(0).font_style = :bold
        # row(0).size = font_size - 1
        columns(2).align = :right
      end

      ## if not last line, add a dashed line
      unless index == @order.deposits.size - 1
        move_down 5
        stroke_dashed_horizontal_line(0, bounds.width)
        move_down 5
      end

      saldo_anterior -= deposit.monto
    end
    move_down 5
    stroke_horizontal_rule
  end

  def factura
    move_down 20
    qr_data = "https://verificacfdi.facturaelectronica.sat.gob.mx/?id=#{@deposit.sat_uuid}&re=#{@corp.rfc}&rr=#{@order.customer.rfc}&tt=#{@deposit.monto}&fe=#{@deposit.sat_cfdi[-8..-1]}"
    qr = RQRCode::QRCode.new(qr_data)
    svg qr.as_svg(module_size: 2), at: [ bounds.width / 2 - 70, cursor ], width: 150
    move_down 20

    text "Folio fiscal:", style: :bold
    text @order.sat_uuid

    move_down 5
    text "Sello digital del CFDI:", style: :bold
    text @order.sat_cfdi

    move_down 5
    text "Sello del SAT:", style: :bold
    text @order.sat_sello
  end

  private

  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end

  def stroke_dashed_horizontal_line(x1, x2, options = {})
    options = options.dup
    line_length = options.delete(:line_length) || 5
    space_length = options.delete(:space_length) || line_length
    period_length = line_length + space_length
    total_length = x2 - x1

    (total_length/period_length).ceil.times do |i|
      left_bound = x1 +  i * period_length
      stroke_horizontal_line(left_bound, left_bound + line_length, options)
    end
  end
end
