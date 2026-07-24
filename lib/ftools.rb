module Ftools
  def self.get_models
    Rails.application.eager_load!
    ApplicationRecord.descendants.map { |model| model.name }.sort
  end


  def self.timbra_bill(bill, uso_cfdi = "G03")
    @setting = Setting.find(1)
    @factura = self.set_bill(@setting)
    time_noww = Time.current
    fecha_timbre = time_noww.strftime("%Y-%m-%dT%H:%M:%S")
    metodo = "PUE"
    forma_pago = Bill.forma_pagos[bill.forma_pago]

    params = {
      moneda: "MXN",
      series: "FA",
      folio: bill.folio || bill.id,
      forma_pago: forma_pago,
      metodo_pago: metodo,
      cp: @setting.cp,
      receptor_cp: (bill.corp and bill.corp.cp) ? (bill.corp.rfc == "XAXX010101000" ? @setting.cp : bill.corp.cp) : @setting.cp,
      receptor_razon: bill.corp.razon,
      receptor_rfc: bill.corp.rfc,
      receptor_regimen: bill.corp.regimen,
      uso_cfdi: (bill.corp and bill.corp.rfc == "XAXX010101000") ? "S01" : uso_cfdi,
      time: fecha_timbre,
      line_items: bill.line_items.map do |line|
        {
          clave_prod_serv: "25172500",
          clave_unidad: "E48",
          unidad: "E48",
          sku: "001",
          cantidad: line.cantidad,
          descripcion: line.nombre,
          valor_unitario: line.precio_descuento,
          descuento: 0.0,
          tax: line.iva,
          retencion_iva: 0
        }
      end
    }

    response = @factura.timbra_doc(params)

    if response[:status] == 200
      puts " --- Timbrado con exito"
      puts response.inspect
      puts "--------------------------------"

      bill.xml = response[:xml]
      bill.sat_uuid = response[:uuid]
      bill.sat_timbre_fecha = response[:fecha_timbrado]
      bill.sat_cfdi = response[:sello_cfd]
      bill.sat_sello = response[:sello_sat]
      bill.sat_sello_emisor = response[:no_certificado_sat]
      bill.sat_serial = @factura.serial
      bill.tipo = "factura"

      bill.error = nil
      bill.save

      ## Si la orden era a credito y remision y ya tenia algunos depositos, timbrarlos
      if bill.deposits.any? and bill.credito?
        bill.deposits.each do |dep|
          self.timbra_deposito(bill, dep)
        end
      end
      true
    else
      puts " --- Timbrado fallido"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      bill.error = response[:message_error]
      bill.tipo = "remision"
      bill.save
      false
    end
  end

  def self.cancela_bill(bill)
    @setting = Setting.find(1)
    @factura = self.set_bill(@setting)

    params = {
      uuid: bill.sat_uuid,
      rfcReceptor: bill.corp.rfc,
      total_sale: bill.total,
      motivo: "02"
    }

    response = @factura.cancela_doc(params)
    if response[:status] == 200
      puts " --- Cancelación con éxito"
      puts response.inspect
      puts "--------------------------------"
      bill.xml = response[:xml]
      bill.error = nil
      bill.save
      true
    else
      puts " --- Cancelación fallida"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      bill.error = response[:message_error]
      bill.save
      false
    end
  end

  def self.timbra_order(order, uso_cfdi = "G03")
    @factura = self.set_factura(order)
    @alias = order.corp
    time_noww = Time.current

    # fecha_timbre = order.fecha.strftime("%Y-%m-%dT%H:%M:%S")
    # fecha_timbre = Time.current.strftime("%Y-%m-%dT%H:%M:%S")

    # Usar fecha de orden si está dentro de 72 horas, sino fecha actual
    diferencia = time_noww.to_time - order.fecha.to_time
    if diferencia <= 72.hours
      puts "Diferencia: #{diferencia}"
      puts "✅ Orden dentro de las 72 horas (#{diferencia / 1.hour}h). Usando fecha de la orden."
      fecha_timbre = order.fecha.strftime("%Y-%m-%dT%H:%M:%S")
    else
      puts "⚠️  Han pasado #{diferencia / 1.hour} horas desde la orden. Usando fecha actual para timbrado."
      fecha_timbre = time_noww.strftime("%Y-%m-%dT%H:%M:%S")
    end

    if order.pagado?
      metodo = "PUE"
      forma_pago = Order.forma_pagos[order.forma_pago]

      ## validar si es deposito_efectivo y cambiar forma_pago a 01 (porque al sat no le gusta ese)
      if forma_pago == "101"
        forma_pago = "01"
      end
    else
      metodo = "PPD"
      forma_pago = "99"
    end

    items = order.line_items.map do |line|
      {
        clave_prod_serv: line.item.sat_product ? line.item.sat_product.sku : "25172500",
        clave_unidad: line.item.unidad,
        unidad: line.item.unidad,
        sku: line.item.sku,
        cantidad: line.cantidad,
        descripcion: "#{line.item.brand.name} - #{line.item.name}",
        valor_unitario: line.precio_descuento,
        descuento: 0.0,
        tax: line.iva,
        retencion_iva: 0
      }
    end
    params = {
      moneda: "MXN",
      series: "FA",
      folio: order.folio || order.id,
      forma_pago: forma_pago,
      metodo_pago: metodo,
      cp: @alias.cp,
      receptor_cp: (order.customer and order.customer.cp) ? (order.customer.rfc == "XAXX010101000" ? @alias.cp : order.customer.cp) : @alias.cp,
      receptor_razon: order.customer.razon,
      receptor_rfc: order.customer.rfc,
      receptor_regimen: order.customer.regimen,
      uso_cfdi: (order.customer and order.customer.rfc == "XAXX010101000") ? "S01" : uso_cfdi,
      time: fecha_timbre,
      line_items: items
    }

    response = @factura.timbra_doc(params)

    if response[:status] == 200
      puts " --- Timbrado con exito"
      puts response.inspect
      puts "--------------------------------"

      order.xml = response[:xml]
      order.sat_uuid = response[:uuid]
      order.sat_timbre_fecha = response[:fecha_timbrado]
      order.sat_cfdi = response[:sello_cfd]
      order.sat_sello = response[:sello_sat]
      order.sat_sello_emisor = response[:no_certificado_sat]
      order.sat_serial = @factura.serial
      order.tipo = "factura"

      order.error = nil
      order.save
      @alias.decrement!(:timbres, 1)

      ## Si la orden era a credito y remision y ya tenia algunos depositos, timbrarlos
      if order.deposits.any? and order.credito?
        order.deposits.each do |dep|
          self.timbra_deposito(order, dep)
        end
      end
      true
    else
      puts " --- Timbrado fallido"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      order.error = response[:message_error]
      order.tipo = "remision"
      order.save
      false
    end
  end

  def self.cancela_order(order)
    @factura = self.set_factura(order)
    @alias = order.corp

    params = {
      uuid: order.sat_uuid,
      rfcReceptor: order.customer.rfc,
      total_sale: order.total,
      motivo: "02"
    }

    response = @factura.cancela_doc(params)
    if response[:status] == 200
      puts " --- Cancelación con éxito"
      puts response.inspect
      puts "--------------------------------"
      order.xml = response[:xml]
      order.error = nil
      order.save
      @alias.decrement!(:timbres, 1)
      true
    else
      puts " --- Cancelación fallida"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      order.error = response[:message_error]
      order.save
      false
    end
  end

  def self.timbra_deposito(order, deposit)
    @factura = self.set_factura(order)
    @alias = order.corp

    timenow = Time.current.strftime("%Y-%m-%dT%H:%M:00")

    ## la fecha del pago no es necesaria convertirla a tiempo de mexico porque
    ##  la ingresa el usuario manualmente en el formulario
    fecha_pago = deposit.created_at.strftime("%Y-%m-%dT%H:%M:00")

    items = order.deposits.collect do |dep|
      {
        monto: dep.monto,
        id: dep.id
      }
    end

    ## find the forma_pago code in the enum
    forma_pago = Deposit.forma_pagos[deposit.forma_pago]

    ## validar si es deposito_efectivo y cambiar forma_pago a 01 (porque al sat no le gusta ese)
    if forma_pago == "101"
      forma_pago = "01"
    end

    params_comp = {
      uuid: order.sat_uuid,
      folio: deposit.id,
      cp: @alias.cp,
      receptor_razon: order.customer.razon,
      receptor_rfc: order.customer.rfc,
      receptor_cp: (order.customer and order.customer.cp) ? order.customer.cp.strip : @alias.cp,
      receptor_regimen: order.customer.regimen_fiscal,
      tasa_iva: 16,
      forma_pago: forma_pago,
      total: order.total.abs,
      monto_pago: deposit.monto.abs,
      saldo_anterior: order.debe.abs,
      num_parcialidad: order.deposits.count.to_s,
      time_pago: fecha_pago,
      time_now: timenow,
      line_items: items
    }

    puts "------ Comprobante de pago -------"
    response = @factura.comp_pago(params_comp)

    if response[:status] == 200
      puts "--- timbrado con exito de deposito"
      puts response.inspect
      puts "--------------------------------"
      deposit.xml = response[:xml]
      deposit.stamp_date = response[:fecha_timbrado]
      deposit.sat_cfdi = response[:sello_cfd]
      deposit.sat_sello = response[:sello_sat]
      deposit.sat_serial = response[:no_certificado_sat]
      deposit.sat_uuid = response[:uuid]
      deposit.sat_error = nil
      deposit.save
      @alias.decrement!(:timbres, 1)
      true
    else
      puts "--- timbrado fallido de deposito"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      deposit.sat_error = response[:message_error]
      deposit.save
      false
    end
  end

  def self.cancela_deposito(order, deposit)
    @factura = self.set_factura(order)
    @alias = order.corp

    params = {
      uuid: deposit.sat_uuid,
      rfcReceptor: order.customer.rfc,
      total_sale: order.total,
      motivo: "02"
    }

    response = @factura.cancela_doc(params)
    if response[:status] == 200
      puts " --- Cancelación con éxito"
      deposit.xml = response[:xml]
      deposit.sat_error = nil
      deposit.save
      @alias.decrement!(:timbres, 1)
      true
    else
      puts " --- Cancelación fallida"
      puts "Status: #{response[:status]}"
      puts "Error details: #{response[:message_error]}"
      deposit.sat_error = response[:message_error]
      deposit.save
      false
    end
  end

  private

  def self.set_bill(setting)
    Factura.new(
      Rails.application.credentials.dig(:factura_key),
      setting.rfc,
      setting.razon,
      setting.regimen,
      ActiveStorage::Blob.service.path_for(setting.key.key),
      setting.key_pass,
      ActiveStorage::Blob.service.path_for(setting.cer.key),
    )
  end

  def self.set_factura(order)
    Factura.new(
      Rails.application.credentials.dig(:factura_key),
      order.corp.rfc,
      order.corp.razon,
      order.corp.regimen,
      ActiveStorage::Blob.service.path_for(order.corp.key.key),
      order.corp.key_pass,
      ActiveStorage::Blob.service.path_for(order.corp.cer.key),
    )
  end
end
