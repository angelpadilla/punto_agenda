class AbonoPdf < Prawn::Document
  def initialize(deposit:)
    super(top_margin: 20)
    @order = deposit.depositable
    @deposit = deposit
    @customer = @order.customer
    @fontsize = 9
    @corp = @order.corp
    font_size @fontsize
    head
    cliente
    body
    factura if @order.tipo == "factura" and @deposit.xml.present?
  end

  def head
    move_down 5

    if @corp.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@corp.logo.key)
      image(logo_path, height: 80)
      move_down 10
    end

    if @deposit.xml.present?
      text "* COMPLEMENTO DE PAGO (ABONO) *", size: (@fontsize + 1), style: :bold
      move_down 10
    end

    y_pos = cursor
    height_box = 120

    text_box(
      %(<strong>Emisor</strong>\n
        <strong>RFC</strong>: #{@corp.rfc}
        <strong>Razon</strong>: #{@corp.razon}
        <strong>Direccion</strong>: #{@corp.calle.titleize} #{@corp.num_ext} #{@corp.num_int}, #{@corp.colonia}, #{@corp.ciudad}, #{@corp.estado.titleize}
        <strong>Tel</strong>: #{@corp.phone}
      ),
      at: [ 0, y_pos ],
      width: (bounds.width / 2),
      height: height_box,
      overflow: :shrink_to_fit,
      inline_format: true,
    )

      text_box(
        %(<strong>Folio</strong>: #{@deposit.folio}
        <strong>Fecha</strong>: #{@deposit.created_at.strftime('%d/%m/%Y')}
        <strong>Forma de pago</strong>: #{@deposit.forma_pago&.titleize}
        #{@deposit.xml.present? ? "<strong>Uso CFDI</strong>: #{@deposit.uso_cfdi}" : nil}
        <strong>Detalles venta</strong>
        <strong>Folio venta</strong>: #{@order.folio}
        <strong>Estatus de venta</strong>: #{@order.status_pago&.titleize}
        <strong>Uso CFDI</strong>: Por definir
        <strong>Forma de pago</strong>: #{@order.forma_pago&.titleize}
        ),
        at: [ (bounds.width / 2), y_pos ],
        width: (bounds.width / 2),
        height: height_box,
        overflow: :shrink_to_fit,
        inline_format: true,
      )

    move_down height_box
  end

  def cliente
    move_down 10
    text "Receptor", style: :bold, size: (@fontsize)
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

  def body
    move_down 10

    if @deposit.xml.present?
      table_content = [
        [ "Unidad", "Clave Prod. Serv.", "Metodo", "Concepto", "Cantidad", "Monto" ],
        [ "ACT", "84111506", @deposit.forma_pago&.titleize, "Pago", "1", number_to_currency(@deposit.monto) ]
      ]
    else
      table_content = [
        [ "Concepto", "Metodo", "Cantidad", "Monto" ],
        [ "Pago", @deposit.forma_pago&.titleize, "1", number_to_currency(@deposit.monto) ]
      ]
    end

    text "Detalles de complemento (abono)", style: :bold, size: (@fontsize + 1)
    move_down 5
    table(table_content) do
      self.header = true
      row(0).font_style = :bold
      self.cell_style = { size: @fontsize, borders: [], padding: 3 }
      self.row_colors = [ "F4F4F4", "ffffff" ]
      self.width = 540
    end
    move_down 25

    text "Historial de abonos", style: :bold, size: (@fontsize + 1)
    move_down 5
    table(items_abono) do
      self.header = true
      row(0).font_style = :bold
      self.cell_style = { size: @fontsize, borders: [], padding: 3 }
      self.row_colors = [ "F4F4F4", "ffffff" ]
      self.width = 540
    end

    move_down 20
  end

  def items_abono
    header = [ [ "Num parcialidad", "Folio interno", "Método pago", "Saldo anterior", "Saldo pagado", "Saldo insoluto" ] ]

    items = []
    saldo_anterior = @order.total
    @order.deposits.each_with_index do |dep, index|
      item = [
        (index + 1).to_s,
        dep.folio,
        dep.forma_pago&.titleize,
        saldo_anterior.to_s,
        dep.monto.to_s,
        (saldo_anterior - dep.monto).to_s
      ]
      saldo_anterior -= dep.monto
      items << item
    end

    header + items
  end

  def factura
    move_down 20

    y_pos = cursor
    qr = RQRCode::QRCode.new("https://verificacfdi.facturaelectronica.sat.gob.mx/?id=#{@deposit.sat_uuid}&re=#{@corp.rfc}&rr=#{@order.customer.rfc}&tt=#{@deposit.monto}&fe=#{@deposit.sat_cfdi[-8..-1]}")
    svg "#{qr.as_svg}", at: [ 0, y_pos ], width: 150

    bounding_box([ 160, y_pos ], width: 370, height: 180) do
      text "Sello digital del CFDI", size: 7, style: :bold
      text "#{@deposit.sat_cfdi}", size: 7
      move_down 5

      text "Sello del SAT", size: 7, style: :bold
      text "#{@deposit.sat_sello}", size: 7
      move_down 5

      text "Folio fiscal", size: 7, style: :bold
      text "#{@deposit.sat_uuid}", size: 7
      move_down 5

      text "Número de serie del certificado del SAT", size: 7, style: :bold
      text "#{@deposit.sat_serial}", size: 7
      move_down 5

      text "Fecha y hora de certificación", size: 7, style: :bold
      text "#{@deposit.stamp_date}", size: 7
      move_down 5

      text "Este documento es una representación impresa de un CFDI", size: 7
    end
  end

  private
  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end

end
