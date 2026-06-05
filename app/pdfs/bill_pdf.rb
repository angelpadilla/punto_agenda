class BillPdf < Prawn::Document
  def initialize(bill)
    super(top_margin: 20)
    @bill = bill
    @setting = Setting.find(1)
    @corp = bill.corp
    font_size 9

    head
    cliente
    items
    totales
    factura if @bill.tipo == "factura" and @bill.xml.present?
    bar_code
  end

  def head
    # font 'Courier'
    # text "Let's see which font we are using: #{font.inspect}"
    move_down 5

    if @setting.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@setting.logo.key)
      image(logo_path, height: 50)
      move_down 20
    end

    # text "<color rgb='ff0000'>Fecha:</color> #{@bill.created_at.strftime('%d/%m/%Y %I:%M %p')}", size: 9, inline_format: true
    y_pos = cursor
    height_box = 80

    text_box(
      %(<strong>Emisor</strong> \n
        <strong>#{@setting.name}</strong>
        #{@setting.rfc.present? ? "<strong>RFC</strong>: #{@setting.rfc}" : nil }
        #{@setting.razon.present? ? "<strong>Razon</strong>: #{@setting.razon}" : nil }
        #{(@setting.calle.present? and @setting.num_ext.present?) ? "<strong>Direccion</strong>: #{@setting.calle.titleize} #{@setting.num_ext} #{@setting.num_int}, #{@setting.colonia}, #{@setting.ciudad}, #{@setting.estado.titleize}" : nil }
        <strong>Tel</strong>: #{@setting.phone}
      ),
      at: [ 0, y_pos ],
      width: (bounds.width / 2),
      height: height_box,
      overflow: :shrink_to_fit,
      inline_format: true,
    )

    if @bill.tipo == "factura"
      text_box(
        %(<strong>Detalles</strong> \n
          <strong>Folio</strong>: #{@bill.folio}
          <strong>Fecha folio</strong>: #{@bill.created_at.strftime('%d/%m/%Y')}
          <strong>Forma de pago</strong>: #{@bill.forma_pago&.titleize}
          <strong>Estatus de venta</strong>: #{@bill.status_pago&.titleize}
          <strong>Uso CFDI</strong>: #{@bill.uso_cfdi}
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
          <strong>Folio</strong>: #{@bill.folio}
          <strong>Fecha folio</strong>: #{@bill.created_at.strftime('%d/%m/%Y')}
          <strong>Forma de pago</strong>: #{@bill.forma_pago&.titleize}
          <strong>Estatus del pago</strong>: #{@bill.status_pago&.titleize}
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

    text "<strong>Razon</strong>: #{@corp.razon.present? ? @corp.razon : @corp.name}", inline_format: true
    text "<strong>RFC</strong>: #{@corp.rfc}", inline_format: true
    text "<strong>Estado</strong>: #{@corp.estado}", inline_format: true if @corp.estado.present?
    text "<strong>C.P.</strong>: #{@corp.cp}, #{@corp.estado}", inline_format: true if @corp.cp.present?
    text "<strong>Ciudad</strong>: #{@corp.ciudad}", inline_format: true if @corp.ciudad.present?
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

    if @bill.tipo == "factura"
      text "<strong>Subtotal</strong>: #{number_to_currency(@bill.subtotal.round(4))} #{@bill.moneda}", inline_format: true
      text "<strong>IVA (16%)</strong>: #{number_to_currency(@bill.impuestos.round(4))} #{@bill.moneda}", inline_format: true
      text "------------------------------------------------"
      text "<strong>Total</strong>: #{number_to_currency(@bill.total.round(4))} #{@bill.moneda}", inline_format: true
    else
      text "<strong>Subtotal</strong>: #{number_to_currency(@bill.subtotal.round(2))} #{@bill.moneda}", inline_format: true
      text "<strong>IVA (16%)</strong>: #{number_to_currency(@bill.impuestos.round(2))} #{@bill.moneda}", inline_format: true
      text "------------------------------------------------"
      text "<strong>Total</strong>: #{number_to_currency(@bill.total.round(2))} #{@bill.moneda}", inline_format: true
    end

    # move_down 10
    # text "Obervaciones", style: :bold, color: '3764ED'
    # text "* Precios presentados en dolares, al momento de procesar el pago y factura se hara la conversión a pesos mexicanos correspondiente.", size: 7
  end


  def factura
    move_down 20

    # text "tamaño de hoja: #{bounds.width}"
    y_pos = cursor
    qr = RQRCode::QRCode.new("https://verificacfdi.facturaelectronica.sat.gob.mx/?id=#{@bill.sat_uuid}&re=#{@setting.rfc}&rr=#{@corp.rfc}&tt=#{@bill.total}&fe=#{@bill.sat_cfdi[-8..-1]}")
    svg "#{qr.as_svg}", at: [ 0, y_pos ], width: 150

    bounding_box([ 160, y_pos ], width: 370, height: 180) do
      text "Sello digital del CFDI", size: 7, style: :bold
      text "#{@bill.sat_cfdi}", size: 7
      move_down 5

      text "Sello del SAT", size: 7, style: :bold
      text "#{@bill.sat_sello}", size: 7
      move_down 5

      text "Folio fiscal", size: 7, style: :bold
      text "#{@bill.sat_uuid}", size: 7
      move_down 5

      text "Número de serie del certificado del SAT", size: 7, style: :bold
      text "#{@bill.sat_serial}", size: 7
      move_down 5

      text "Fecha y hora de certificación", size: 7, style: :bold
      text "#{@bill.sat_timbre_fecha}", size: 7
      move_down 5

      text "Este documento es una representación impresa de un CFDI", size: 7
    end
  end

  def items_rows
    header = [ [ "Unidad", "Concepto", "Cantidad", "Precio Unitario", "Descuento", "Importe" ] ]
    items = @bill.bill_items.map do |line|
      [
        "Servicio",
        line.nombre,
        line.cantidad,
        number_to_currency(line.precio),
        number_to_currency(line.descuento),
        number_to_currency(line.total)
      ]
    end
    
    header + items
  end

  def bar_code
    move_down 20
    baba = Barby::Code128B.new("#{@bill.folio}")
    svg baba.to_svg(height: 30, margin: 0, xdim: 1), at: [ 0, cursor ], width: 150
  end

  private

  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end
end
