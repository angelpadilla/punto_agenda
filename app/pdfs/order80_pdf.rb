class Order80Pdf < Prawn::Document
  def initialize(order:)
    # Ancho de 80mm en puntos (1mm = 2.83 pt)
    page_width = 72 * 2.8346
    super(page_size: [ page_width, 900 ], margin: [ 0, 5, 0, 0 ])

    @order = order
    @corp = order.corp
    @customer = order.customer

    @timee = Time.current.in_time_zone("America/Mexico_City")

    @fontsize = 7
    font_size @fontsize

    head
    cliente
    items
    totales
    notas
    factura if @order.tipo == "factura"
    bar_code
  end

  def head
    move_down 10
    if @corp.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@corp.logo.key)
      image(logo_path, height: 50, position: :center)
      move_down 10
    end


    text "HORA DE IMPRESION: #{@timee.strftime("%d/%m/%Y %I:%M%p")}", size: @fontsize, align: :left
    move_down 10

    if @order.cotizacion?
      text "*** COTIZACION ***", size: @fontsize, style: :bold, align: :center
      move_down 10
    end

    text "<strong>Folio</strong>: #{@order.folio}", inline_format: true

    text "<strong>Fecha venta</strong>: #{@order.fecha.strftime('%d/%m/%Y')}", inline_format: true
    text "<strong>Forma de pago</strong>: #{@order.forma_pago&.titleize}", inline_format: true unless @order.cotizacion?
    text "<strong>Estatus de venta</strong>: #{@order.status_pago&.titleize}", inline_format: true if @order.status_pago.present? && !@order.cotizacion?

    text "<strong>Tipo</strong>: #{@order.tipo&.titleize}", inline_format: true if @order.cotizacion?

    if @order.tipo == "factura"
      text "<strong>Uso CFDI</strong>: #{@order.uso_cfdi}", inline_format: true
      text "<strong>Metodo de pago</strong>: PUE", inline_format: true
    end
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

  def items
    move_down 5

    font_size = @fontsize
    ancho = bounds.width

    @order.line_items.each_with_index do |line, index|
      name = "#{line.item&.brand&.name} - #{line.item&.name}"
      table([
        [ "Cantidad", "Concepto" ],
        [ line.cantidad.to_i, name ]
      ], width: bounds.width, column_widths: [ (ancho * 0.2), (ancho * 0.8) ]) do
        self.cell_style = { borders: [], padding: 0, size: font_size }
        row(0).font_style = :bold
        # row(0).size = font_size - 1
        columns(1).align = :right
      end
      move_down 3
      table([
        [ "Precio Unitario", "Importe" ],
        [ "#{number_to_currency(line.precio)}", "#{number_to_currency(line.total)}" ]
      ], width: bounds.width, column_widths: [ (ancho * 0.5), (ancho * 0.5) ]) do
        self.cell_style = { borders: [], padding: 0, size: font_size }
        row(0).font_style = :bold
        columns(1).align = :right
      end
      ## if not last line, add a dashed line
      unless index == @order.line_items.size - 1
        move_down 5
        stroke_dashed_horizontal_line(0, bounds.width)
        move_down 5
      end
    end
  end

  def totales
    move_down 5
    stroke_horizontal_rule
    table([
      [ "Subtotal:", "#{number_to_currency(@order.subtotal)}" ],
      [ "IVA:", "#{number_to_currency(@order.impuestos)}" ],
      [ "Total:", "#{number_to_currency(@order.total)}" ]
    ], width: bounds.width) do
      self.cell_style = { borders: [], padding: 2, size: @fontsize }
      columns(0).font_style = :bold
      columns(1).align = :right
    end
  end

  def notas
    move_down 20
    if @order.nota_customer.present?
      text "*** #{@order.nota_customer}"
    end
    if @corp.text_factura.present? and @order.tipo == "factura"
      text @corp.text_factura
    end
    if @corp.text_remision.present? and @order.tipo == "remision"
      text @corp.text_remision
    end
    if @corp.text_cotizacion.present? and @order.cotizacion?
      text @corp.text_cotizacion
    end
  end

  def factura
    move_down 20
    qr_data = "https://verificacfdi.facturaelectronica.sat.gob.mx/?id=#{@order.sat_uuid}&re=#{@corp.rfc}&rr=#{@order.customer.rfc}&tt=#{@order.total}&fe=#{@order.sat_cfdi[-8..-1]}"
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

  def bar_code
    move_down 20
    baba = Barby::Code128B.new("#{@order.folio}")
    svg baba.to_svg(height: 30, margin: 0, xdim: 1), at: [ bounds.width / 2 - 75, cursor ], width: 150
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
