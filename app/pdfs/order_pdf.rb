class OrderPdf < Prawn::Document
  def initialize(order:)
    super(top_margin: 20)
    @order = order
    @corp = order.corp
    @customer = order.customer

    font_size 9

    head
    cliente
    items
    totales
    notas
    factura if @order.tipo == "factura" and @order.xml.present?
  end

  def head
    # font 'Courier'
    # text "Let's see which font we are using: #{font.inspect}"
    move_down 5

    if @corp.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@corp.logo.key)
      image(logo_path, height: 100)
      move_down 10
    end

    if @order.cotizacion?
      text "* COTIZACION *", size: 9, style: :bold
      move_down 10
    end

    # text "<color rgb='ff0000'>Fecha:</color> #{@order.created_at.strftime('%d/%m/%Y %I:%M %p')}", size: 9, inline_format: true
    y_pos = cursor
    height_box = 80

    text_box(
      %(<strong>Emisor</strong> \n
        <strong>#{@corp.name}</strong>
        #{@corp.rfc.present? ? "<strong>RFC</strong>: #{@corp.rfc}" : nil }
        #{@corp.razon.present? ? "<strong>Razon</strong>: #{@corp.razon}" : nil }
        #{(@corp.calle.present? and @corp.num_ext.present?) ? "<strong>Direccion</strong>: #{@corp.calle.titleize} #{@corp.num_ext} #{@corp.num_int}, #{@corp.colonia}, #{@corp.ciudad}, #{@corp.estado.titleize}" : nil }
        <strong>Tel</strong>: #{@corp.phone}
      ),
      at: [ 0, y_pos ],
      width: (bounds.width / 2),
      height: height_box,
      overflow: :shrink_to_fit,
      inline_format: true,
    )

    if @order.tipo == "factura"
      text_box(
        %(<strong>Detalles</strong> \n
          <strong>Folio</strong>: #{@order.sku}
          <strong>Fecha folio</strong>: #{@order.fecha.strftime('%d/%m/%Y')}
          <strong>Forma de pago</strong>: #{@order.forma_pago&.titleize}
          <strong>Estatus de venta</strong>: #{@order.status&.titleize}
          <strong>Uso CFDI</strong>: #{@order.uso_cfdi}
        ),
        at: [ (bounds.width / 2), y_pos ],
        width: (bounds.width / 2),
        height: height_box,
        overflow: :shrink_to_fit,
        inline_format: true,
      )
    else
      text_box(
        %(<strong>Detalles</strong> \n
          <strong>Folio</strong>: #{@order.folio}
          <strong>Fecha folio</strong>: #{@order.fecha.strftime('%d/%m/%Y')}
          #{@order.cotizacion? ? "<strong>Tipo</strong>: Cotización" : nil }
          #{!@order.cotizacion? ? "<strong>Forma de pago</strong>: #{@order.forma_pago&.titleize}" : nil }
          #{!@order.cotizacion? ? "<strong>Estatus del pago</strong>: #{@order.status_pago&.titleize}" : nil }
        ),
        at: [ (bounds.width / 2), y_pos ],
        width: (bounds.width / 2),
        height: height_box,
        overflow: :shrink_to_fit,
        inline_format: true,
      )
    end
    move_down height_box
  end

  def cliente
    move_down 10
    text "Receptor", style: :bold, size: 9
    move_down 5

    if @customer
      text "<strong>Razon</strong>: #{@customer.razon}", inline_format: true
      text "<strong>RFC</strong>: #{@customer.rfc}", inline_format: true
      unless @order.cotizacion?
        text "<strong>Estado</strong>: #{@customer.estado}", inline_format: true if @customer.estado.present?
        text "<strong>C.P.</strong>: #{@customer.cp}, #{@customer.estado}", inline_format: true if @customer.cp.present?
        text "<strong>Ciudad</strong>: #{@customer.ciudad}", inline_format: true if @customer.ciudad.present?
      end
    else
      text "Cliente eliminado de sistema", bold: true
    end
  end

  def items
    move_down 10
    table(items_rows) do
      self.header = true
      row(0).font_style = :bold
      self.cell_style = { size: 8, borders: [], padding: 3 }
      self.row_colors = [ "F4F4F4", "ffffff" ]
      self.width = 540
    end
  end

  def totales
    move_down 20

    if @order.tipo == "factura"
      text "<strong>Subtotal</strong>: #{number_to_currency(@order.subtotal.round(4))} #{@order.moneda}", inline_format: true
      text "<strong>IVA (16%)</strong>: #{number_to_currency(@order.impuestos.round(4))} #{@order.moneda}", inline_format: true
      text "------------------------------------------------"
      text "<strong>Total</strong>: #{number_to_currency(@order.total.round(4))} #{@order.moneda}", inline_format: true
    else
      text "<strong>Subtotal</strong>: #{number_to_currency(@order.subtotal.round(2))} #{@order.moneda}", inline_format: true
      text "<strong>IVA (16%)</strong>: #{number_to_currency(@order.impuestos.round(2))} #{@order.moneda}", inline_format: true
      text "------------------------------------------------"
      text "<strong>Total</strong>: #{number_to_currency(@order.total.round(2))} #{@order.moneda}", inline_format: true
    end

    # move_down 10
    # text "Obervaciones", style: :bold, color: '3764ED'
    # text "* Precios presentados en dolares, al momento de procesar el pago y factura se hara la conversión a pesos mexicanos correspondiente.", size: 7
  end

  def notas
    move_down 20
    if @order.nota_customer.present?
      text "*** #{@order.nota_customer}", size: 8
    end
    if @corp.text_factura.present? and @order.tipo == "factura"
      text @corp.text_factura, size: 8
    end
    if @corp.text_remision.present? and @order.tipo == "remision"
      text @corp.text_remision, size: 8
    end
    if @corp.text_cotizacion.present? and @order.cotizacion?
      text @corp.text_cotizacion, size: 8
    end
  end

  def factura
      move_down 20

      # text "tamaño de hoja: #{bounds.width}"
      y_pos = cursor
      qr = RQRCode::QRCode.new("https://verificacfdi.facturaelectronica.sat.gob.mx/?id=#{@order.sat_uuid}&re=#{@corp.rfc}&rr=#{@order.customer.rfc}&tt=#{@order.total}&fe=#{@order.sat_cfdi[-8..-1]}")
      svg "#{qr.as_svg}", at: [ 0, y_pos ], width: 150

      bounding_box([ 160, y_pos ], width: 370, height: 180) do
        text "Sello digital del CFDI", size: 7, style: :bold
        text "#{@order.sat_cfdi}", size: 7
        move_down 5

        text "Sello del SAT", size: 7, style: :bold
        text "#{@order.sat_sello}", size: 7
        move_down 5

        text "Folio fiscal", size: 7, style: :bold
        text "#{@order.sat_uuid}", size: 7
        move_down 5

        text "Número de serie del certificado del SAT", size: 7, style: :bold
        text "#{@order.sat_serial}", size: 7
        move_down 5

        text "Fecha y hora de certificación", size: 7, style: :bold
        text "#{@order.sat_timbre_fecha}", size: 7
        move_down 5

        text "Este documento es una representación impresa de un CFDI", size: 7
      end
  end

  def items_rows
    if @order.tipo == "factura"
      header = [ [ "Unidad", "Concepto", "Cantidad", "Precio Unitario", "Importe" ] ]
      if @order.facturado_especial_madre
        items = @order.line_items.map do |line|
          [
            line.item.unidad,
            "Factura conjunta de folios: #{@order.ids_facturados_especial.split(',').join(', ')}",
            line.cantidad,
            "$#{line.precio} #{@order.moneda}",
            "$#{line.total} #{@order.moneda}"
          ]
        end
      else
        items = @order.line_items.map do |line|
          [
            line.item.unidad,
            "#{line.item.brand.name} - #{line.item.name}",
            line.cantidad,
            "$#{line.precio} #{@order.moneda}",
            "$#{line.total} #{@order.moneda}"
          ]
        end
      end
    else
      header = [ [ "Unidad", "Concepto", "Cantidad", "Precio Unitario", "Importe" ] ]
      items = @order.line_items.map do |line|
        [
          line.item.unidad,
          "#{line.item&.brand&.name&.titleize} - #{line.item.name}",
          line.cantidad,
          number_to_currency(line.precio),
          number_to_currency(line.total)
        ]
      end
    end
    header + items
  end

  private

  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end
end
