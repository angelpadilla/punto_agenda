class Factura
  attr_reader :serial

  UrlPro = "https://v4.cfdis.mx/api/Cfdi"
  UrlCancel = "https://v4.cfdis.mx/api/CfdiCancelacion/Cancelar"

  def initialize(id_servicio, rfc, razon, regimen, doc_key_path, key_pass, doc_cer_path)
    puts "---- Fdis:config:initialize"
    @id_servicio = id_servicio.to_s
    @rfc = rfc.to_s
    @razon = razon.to_s
    @regimen_fiscal = regimen
    @doc_key_path = doc_key_path.to_s
    @key_pass = key_pass.to_s
    @doc_cer_path = doc_cer_path
    @production = Rails.env.production? ? true : false

    puts "------ Fdis: Config inicial ---"
    puts "-- id servicio: #{@id_servicio}"
    puts "-- rfc: #{@rfc}"
    puts "-- razon: #{@razon}"
    puts "-- regimen_fiscal: #{@regimen_fiscal}"
    puts "-- key_path: #{@doc_key_path}"
    puts "-- cer_path: #{@doc_cer_path}"
    puts "-- production: #{@production}"

    key_to_pem
    serial_number
    cer_cadena
  end

  def key_to_pem
    puts "---- Fdis:config:key_to_pem"

    @pem = %x(openssl pkcs8 -inform DER -in #{@doc_key_path} -passin pass:#{@key_pass})
    # @pem = %x[openssl rsa -inform DER -in #{@doc_key_path} -passin pass:#{@key_pass}]
    @pem_cadena = @pem.clone
    @pem_cadena.slice!("-----BEGIN PRIVATE KEY-----")
    @pem_cadena.slice!("-----END PRIVATE KEY-----")
    @pem_cadena.delete!("\n")
  end

  def serial_number
    puts "---- Fdis:config:serial_number"

    response = %x(openssl x509 -inform DER -in #{@doc_cer_path} -noout -serial)
    d_begin = response.index(/\d/)
    number = (response[d_begin..-1]).chomp
    final_serial = ""

    number.each_char.with_index do |s, index|
      if (index + 1).even?
        final_serial << s
      end
    end

    @serial = final_serial
  end


  def cer_cadena
    puts "---- Fdis:config:cer_cadena"

    file = File.read(@doc_cer_path)
    text_certificate = OpenSSL::X509::Certificate.new(file)
    cert_string = text_certificate.to_s
    cert_string.slice!("-----BEGIN CERTIFICATE-----")
    cert_string.slice!("-----END CERTIFICATE-----")
    cert_string.delete!("\n")
    @cadena = cert_string
  end

  def comp_pago(params = {})
    # Sample params
    # params = {
    # 	uuid: '',
    # 	folio: '',
    #   cp: '',
    # 	receptor_razon: 'Car zone',
    #   receptor_rfc: 'XAXX010101000',
    #   receptor_cp: '47180',
    #   receptor_regimen: '616',
    # 	tasa_iva: 0, 16, se toma tasa iva de factura madre
    #   forma_pago: '01',
    #   total: 100.00,
    #   monto_pago: 50.0,
    #   saldo_anterior: 100.0,
    #   num_parcialidad: '1',
    # 	time_pago: '',
    # 	time_now: '',
    # 	modena: '',
    # 	line_items: [
    # 		{
    # 			monto: 60.00,
    # 			moneda: '',
    #       id: ,
    # 		},
    # 	]
    # }

    puts "----- Fdis: Facturacion::com_pago"
    puts "--- Fdis: Total venta: #{params[:total]}"
    puts "--- Fdis: Monto de pago a procesar: #{params[:monto_pago]}"
    puts "--- Fdis: Saldo insoluto anterior: #{params[:saldo_anterior]}"
    puts "--- Fdis: fecha now: #{params[:time_now]}"
    puts "--- Fdis: fecha pago: #{params[:time_pago]}"
    puts "--- Fdis: Line items: "
    params[:line_items].each do |line|
      puts "-- #{line[:monto]}"
    end
    lines_total = params[:line_items].inject(0) { |sum, x| sum + x[:monto].to_f }

    puts "--- Fdis: Suma de lineas: #{lines_total}"

    if lines_total > params[:total].to_f
      raise "Error Fdis - la suma de los complementos de pago es mayor al total de la venta"
    end

    unless params[:time_pago] and params[:time_pago].size > 0
      raise "Error Fdis - la fecha de timbrado debe de estar presente"
    end

    if params[:num_parcialidad].empty?
      raise "Error Fdis - Se debe registrar el número de parcialidad que corresponde al pago"
    end

    if params[:uuid].blank?
      raise "Error Fdis - El UUID de la factura original es requerido para generar el complemento de pago"
    end




    time_now = params.fetch(:time_now, Time.now.in_time_zone("America/Mexico_City").strftime("%Y-%m-%dT%H:%M:%S"))
    time_pago = params[:time_pago]


    base_doc = %(<?xml version="1.0" encoding="UTF-8"?>
      <cfdi:Comprobante xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:pago20="http://www.sat.gob.mx/Pagos20" xsi:schemaLocation="http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd" Version="4.0" Serie="" Folio="" Fecha="" Sello="" NoCertificado="" Certificado="" SubTotal="0" Moneda="XXX" Total="0" TipoDeComprobante="P" Exportacion="01" LugarExpedicion="" xmlns:cfdi="http://www.sat.gob.mx/cfd/4">

        <cfdi:Emisor Rfc="" Nombre="" RegimenFiscal="" />
        <cfdi:Receptor Rfc="" Nombre="" UsoCFDI="CP01" DomicilioFiscalReceptor="" RegimenFiscalReceptor="616" />

        <cfdi:Conceptos>
          <cfdi:Concepto ClaveProdServ="84111506" Cantidad="1" ClaveUnidad="ACT" Descripcion="Pago" ValorUnitario="0" Importe="0" ObjetoImp="01" />
        </cfdi:Conceptos>

        <cfdi:Complemento>

          <pago20:Pagos Version="2.0">
            <pago20:Totales MontoTotalPagos="" />

            <pago20:Pago FechaPago="" FormaDePagoP="" MonedaP="MXN" Monto="" TipoCambioP="1">

              <pago20:DoctoRelacionado IdDocumento="" MonedaDR="MXN" NumParcialidad="" ImpSaldoAnt="" ImpPagado="" ImpSaldoInsoluto="" ObjetoImpDR="02" EquivalenciaDR="1">


              </pago20:DoctoRelacionado>

            </pago20:Pago>

          </pago10:Pagos>

        </cfdi:Complemento>

      </cfdi:Comprobante>)

    base_doc.delete!("\n")
    base_doc.delete!("\t")

    xml = Nokogiri::XML(base_doc)
    comprobante = xml.at_xpath("//cfdi:Comprobante")
    comprobante["Serie"] = "P"
    comprobante["Folio"] = params[:folio].to_s
    comprobante["Fecha"] = time_now
    comprobante["LugarExpedicion"] = params[:cp].to_s
    comprobante["NoCertificado"] = @serial
    comprobante["Certificado"] = @cadena

    # Emisor datos
    emisor = xml.at_xpath("//cfdi:Emisor")
    emisor["Rfc"] = @rfc
    emisor["Nombre"] = @razon
    emisor["RegimenFiscal"] = @regimen_fiscal

    # Receptor datos
    receptor = xml.at_xpath("//cfdi:Receptor")
    receptor["Nombre"] = params[:receptor_razon].to_s
    receptor["Rfc"] = params[:receptor_rfc].to_s
    receptor["DomicilioFiscalReceptor"] = params.fetch(:receptor_cp, "47180")
    receptor["RegimenFiscalReceptor"] = params.fetch(:receptor_regimen, "616")


    # totales
    total = params[:monto_pago].to_f.abs
    iva_id = params.fetch(:tasa_iva, 16)

    pago_totales = xml.at_xpath("//pago20:Totales")
    pago_totales["MontoTotalPagos"] = total.round(2).to_s # total




    if iva_id == 0
      subtotal = total
      iva = 0.00

      pago_totales["TotalTrasladosBaseIVA0"] = subtotal.round(2).to_s # subtotal
      pago_totales["TotalTrasladosImpuestoIVA0"] =  iva.round(2).to_s # iva

    else
      subtotal = total / 1.16
      iva = total - subtotal

      pago_totales["TotalTrasladosBaseIVA16"] = subtotal.round(2).to_s # subtotal
      pago_totales["TotalTrasladosImpuestoIVA16"] =  iva.round(2).to_s # iva
    end


    # pagos = xml.at_xpath("//pago20:Pagos")

    # pago
    child_pago = xml.at_xpath("//pago20:Pago")

    child_pago["FechaPago"] = time_pago
    child_pago["FormaDePagoP"] = params[:forma_pago].to_s
    child_pago["MonedaP"] = params.fetch(:moneda, "MXN")
    child_pago["Monto"] = total.round(2).to_s
    child_pago["TipoCambioP"] = "1"

    child_pago_relacionado = xml.at_xpath("//pago20:DoctoRelacionado")

    child_pago_relacionado["IdDocumento"] = params[:uuid]
    child_pago_relacionado["MonedaDR"] = "MXN"
    child_pago_relacionado["NumParcialidad"] = params[:num_parcialidad]
    child_pago_relacionado["Serie"] = "Depo"
    child_pago_relacionado["Folio"] = params[:folio]
    child_pago_relacionado["EquivalenciaDR"] = "1"

    saldo_anterior = params[:saldo_anterior].to_f.abs

    child_pago_relacionado["ImpSaldoAnt"] = saldo_anterior.round(2).to_s
    child_pago_relacionado["ImpPagado"] = total.round(2).to_s
    child_pago_relacionado["ImpSaldoInsoluto"] = (saldo_anterior - total).round(2).abs.to_s
    child_pago_relacionado["ObjetoImpDR"] = "02"

    impuestos_dr = Nokogiri::XML::Node.new "pago20:ImpuestosDR", xml
    traslados_dr = Nokogiri::XML::Node.new "pago20:TrasladosDR", xml
    traslado = Nokogiri::XML::Node.new "pago20:TrasladoDR", xml

    impuestos_p = Nokogiri::XML::Node.new "pago20:ImpuestosP", xml
    traslados_p = Nokogiri::XML::Node.new "pago20:TrasladosP", xml
    traslado_p = Nokogiri::XML::Node.new "pago20:TrasladoP", xml

    traslado["TipoFactorDR"] = "Tasa"
    traslado["ImpuestoDR"] = "002"

    traslado["BaseDR"] =  subtotal.round(2).to_s # subtotal
    traslado["ImporteDR"] = iva.round(2).to_s # tax

    traslado_p["BaseP"] = subtotal.round(2).to_s
    traslado_p["ImpuestoP"] = "002"
    traslado_p["TipoFactorP"] = "Tasa"
    traslado_p["ImporteP"] = iva.round(2).to_s # tax

    if iva_id == 16
      traslado["TasaOCuotaDR"] = "0.160000"
      # t_subtotal = total / 1.16
      # t_tax = total - t_subtotal

      traslado_p["TasaOCuotaP"] = "0.160000"

    else
      traslado["TasaOCuotaDR"] = "0.000000"
      traslado_p["TasaOCuotaP"] = "0.000000"
    end

    traslados_dr.add_child(traslado)
    impuestos_dr.add_child(traslados_dr)
    child_pago_relacionado.add_child(impuestos_dr)

    traslados_p.add_child(traslado_p)
    impuestos_p.add_child(traslados_p)
    child_pago.add_child(impuestos_p)



    # puts '---------------- Xml resultante comprobante de pago -----------------------'
    # puts xml.to_xml
    # puts '--------------------------------------------------------'

    path = File.join(File.dirname(__FILE__), *%w[.. tmp])
    id = SecureRandom.hex

    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.write("#{path}/tmp_c_#{id}.xml", xml.to_xml)
    xml_path = "#{path}/tmp_c_#{id}.xml"
    cadena_path = File.join(File.dirname(__FILE__), *%w[cadena cadenaoriginal_4_0.xslt])

    File.write("#{path}/pem_#{id}.pem", @pem)
    key_pem_url = "#{path}/pem_#{id}.pem"
    sello = %x(xsltproc #{cadena_path} #{xml_path} | openssl dgst -sha256 -sign #{key_pem_url} | openssl enc -base64 -A)
    comprobante["Sello"] = sello

    File.delete("#{xml_path}")
    File.delete("#{key_pem_url}")

    puts "------ Fdis: comprobante de pago antes de timbre -------"
    puts xml.to_xml
    base64_xml = Base64.encode64(xml.to_xml)

    # haciendo llamada a API
    uri = URI("#{UrlPro}/Timbrar40")
    request = Net::HTTP::Post.new(uri)
    # request.basic_auth(token, "")
    request.content_type = "application/json"
    # request["cache-control"] = 'no-cache'
    request.body = JSON.dump({
      "testMode": !@production,
      "idServicio": @id_servicio,
      "base64XmlFile": base64_xml
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    json_response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    puts "---- Fdis: request"
    puts "-- body: #{request.body} --"

    puts "---- Fdis: Respuestaaaaaaa"
    puts "-- Codigo: #{json_response.code} --"
    puts "-- Mensaje: #{json_response.message} --"
    puts "-- Body: "
    p json_response.body
    puts "-------------------------"
    response = JSON.parse(json_response.body)

    case json_response
    when Net::HTTPSuccess, Net::HTTPRedirection
      if response["success"] == true
        ns = {
          "cfdi" => "http://www.sat.gob.mx/cfd/4",
          "tfd"  => "http://www.sat.gob.mx/TimbreFiscalDigital"
        }
        doc = Nokogiri::XML(Base64.decode64(response["base64XmlFile"]))
        timbre = doc.at_xpath("//tfd:TimbreFiscalDigital", ns)
        response = {
          status: 200,
          message_error: "",
          xml: doc.to_xml,
          uuid: timbre["UUID"],
          fecha_timbrado: timbre["FechaTimbrado"],
          sello_cfd: timbre["SelloCFD"],
          sello_sat: timbre["SelloSAT"],
          no_certificado_sat: timbre["NoCertificadoSAT"]
        }
        response
      else
        response = {
          status: 400,
          message_error: "Error: #{response['errorMessages']}",
          xml: "",
          uuid: "",
          fecha_timbrado: "",
          sello_cfd: "",
          sello_sat: "",
          no_certificado_sat: ""
        }
        response

      end
    else
      response = {
        status: json_response.code,
        message_error: "Error: #{response['errorMessages']}",
        xml: "",
        uuid: "",
        fecha_timbrado: "",
        sello_cfd: "",
        sello_sat: "",
        no_certificado_sat: ""
      }
      response

    end
  end

  def cancela_doc(params = {})
    puts "---- Fdis:facturacion:cancela_doc"

    # Sample params
    # params = {
    # 	uuid: '',
    # 	rfcReceptor: 'XAXX010101000',
    # 	total_sale: 100.0,
    # 	motivo: '02',
    # 	uuid_sustituye: '',
    # 	key_password: '', # optional
    # 	cer_cadena: '', # optional
    # 	key_pem: '' # optional
    # }


    uri = URI(UrlCancel)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"

    request.body = JSON.dump({
      rfcEmisor: @rfc,
      rfcReceptor: params[:rfcReceptor],
      keyPassword: @key_pass,
      totalCfdi: params[:total_sale],
      uuid: params[:uuid],
      motivoCancelacion: params.fetch(:motivo, "02"),
      FolioFiscalSustituye: params.fetch(:uuid_sustituye, SecureRandom.uuid.upcase),
      testMode: !@production,
      base64CerFile: params.fetch(:cer_cadena, @cadena),
      base64KeyFile: params.fetch(:key_pem, @pem_cadena)
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    json_response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    puts "---- Fdis: request"
    puts "-- body: #{request.body} --"

    puts "---- Fdis: Respuesta"
    puts "-- Codigo: #{json_response.code} --"
    puts "-- Mensaje: #{json_response.message} --"
    puts "-- Body: "
    p json_response.body

    response = JSON.parse(json_response.body)

    case json_response
    when Net::HTTPSuccess, Net::HTTPRedirection
      if response["success"] == true
        acuse = response["acuseCancelacion"]
        response = {
          status: 200,
          message_error: "",
          xml: acuse
        }

        response
      else
        response = {
          status: 400,
          message_error: "Error: #{response['errors']}",
          xml: ""

        }
        response
      end

    else
      response = {
        status: 400,
        message_error: "Error: #{response['errors']}",
        xml: ""

      }
      response
    end
  end

  def timbra_doc(params = {})
    ### sample paramss
    #
    # params = {
    # 	moneda: 'MXN',
    # 	series: 'FA',
    # 	folio: '003',
    # 	forma_pago: '',
    # 	metodo_pago: 'PUE',
    # 	cp: '47180',
    # 	receptor_cp: '47180',
    # 	receptor_razon: 'Car zone',
    # 	receptor_rfc: '',
    # 	receptor_regimen: '',
    # 	uso_cfdi: 'G03',
    #   time: "%Y-%m-%dT%H:%M:%S",
    # 	line_items: [
    # 		{
    # 			clave_prod_serv: '78181500',
    #  			clave_unidad: 'E48',
    #  			unidad: 'Servicio',
    #  			sku: 'serv001',
    #  			cantidad: 1,
    #  			descripcion: 'Servicio mano de obra',
    #  			valor_unitario: 100.00,
    #  			descuento: 0.00,
    #  			tax: 16.0 o 0.0,
    #       retencion_iva: 0, 6, 16
    #  			# Optional parameters
    # 		},
    # 	]

    # }

    puts "---- Fdis:facturacion:timbra_doc"

    puts "--- Fdis: Datos --------"
    puts "--- Fdis: Line items: "
    params[:line_items].each do |line|
      puts "----- valor unitario: #{line[:valor_unitario]}"
      puts "----- cantidad: #{line[:cantidad]}"
    end

    time = params.fetch(:time, Time.now.in_time_zone("America/Mexico_City").strftime("%Y-%m-%dT%H:%M:%S"))


    base_doc = %(<?xml version="1.0" encoding="utf-8"?>
    <cfdi:Comprobante xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd" Version="4.0" xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Fecha="" Serie="" Folio="" FormaPago="" SubTotal="" Moneda="MXN" Total="" TipoDeComprobante="I" MetodoPago="" LugarExpedicion="" Certificado="" NoCertificado="" Sello="" Exportacion="01">

      <cfdi:Emisor Rfc="" Nombre="" RegimenFiscal="" />
      <cfdi:Receptor Rfc="" Nombre="" DomicilioFiscalReceptor="" RegimenFiscalReceptor="" UsoCFDI="" />

      <cfdi:Conceptos></cfdi:Conceptos>
      <cfdi:Impuestos></cfdi:Impuestos>

    </cfdi:Comprobante>)

    base_doc.delete!("\n")
    base_doc.delete!("\t")

    xml = Nokogiri::XML(base_doc)
    comprobante = xml.at_xpath("//cfdi:Comprobante")
    comprobante["TipoCambio"] = "1"
    comprobante["TipoDeComprobante"] = "I"
    comprobante["Serie"] = params.fetch(:series, "FA").to_s
    comprobante["Folio"] = params.fetch(:folio).to_s
    comprobante["Fecha"] = time.to_s
    comprobante["MetodoPago"] = params.fetch(:metodo_pago, "PUE")
    comprobante["FormaPago"] = params.fetch(:forma_pago, "01")

    if comprobante["MetodoPago"] == "PPD"
      comprobante["FormaPago"] = "99"
    end


    comprobante["LugarExpedicion"] = params.fetch(:cp, "47180")
    comprobante["NoCertificado"] = @serial
    comprobante["Certificado"] = @cadena

    # emisor
    emisor = xml.at_xpath("//cfdi:Emisor")
    emisor["Nombre"] = @razon
    emisor["RegimenFiscal"] = @regimen_fiscal
    emisor["Rfc"] = @rfc

    # receptor
    receptor = xml.at_xpath("//cfdi:Receptor")
    receptor["Rfc"] = params.fetch(:receptor_rfc, "")
    receptor["Nombre"] = params.fetch(:receptor_razon, "")
    receptor["DomicilioFiscalReceptor"] = params.fetch(:receptor_cp, "47180")
    if params[:receptor_rfc] == "XAXX010101000"
      receptor["UsoCFDI"] = "S01"
      receptor["RegimenFiscalReceptor"] = "616"
    else
      receptor["UsoCFDI"] = params.fetch(:uso_cfdi, "G03")
      # receptor['RegimenFiscalReceptor'] = params.fetch(:receptor_regimen, '616')
      receptor["RegimenFiscalReceptor"] = params[:receptor_regimen]
    end

    # retencion_iva = params.fetch(:retencion_iva, 0)

    impuestos = xml.at_xpath("//cfdi:Impuestos")
    traslados = Nokogiri::XML::Node.new "cfdi:Traslados", xml


    puts "--- Fdis time -----"
    puts time
    puts "--------"

    conceptos = xml.at_xpath("//cfdi:Conceptos")

    line_items = params[:line_items]

    suma_total = 0.00
    subtotal = 0.00
    suma_iva = 0.00
    suma_ret = 0.00


    line_items.each do |line|
      iva_id = line.fetch(:tax, 16.0).to_f

      ret_iva = line.fetch(:retencion_iva, 0)

      cantidad = line[:cantidad].to_f



      # if line[:tipo_impuesto] == '004'
      # total_acumulator = cantidad * valor_unitario
      # else
      # total_acumulator = cantidad * valor_unitario * 1.16
      # end

      ## TODO: ajustar todo a facturacion con iva cero

      total_acumulator = cantidad * line[:valor_unitario].to_f

      if iva_id > 0
        tax_factor = (iva_id / 100) + 1
        valor_unitario = (line[:valor_unitario].to_f) / tax_factor
      else
        valor_unitario = line[:valor_unitario].to_f
      end

      # if iva_id == 16
      # 	valor_unitario = (line[:valor_unitario].to_f) / 1.16
      # else
      # 	valor_unitario = line[:valor_unitario].to_f
      # end

      subtotal_line = cantidad * valor_unitario
      importe_iva = total_acumulator - subtotal_line

      subtotal += subtotal_line
      suma_iva += importe_iva
      suma_total += total_acumulator

      ## calculando retencion de IVA en caso de tener
      if ret_iva > 0
        if ret_iva == 6
            importe_ret_linea = (subtotal_line * 1.06) - subtotal_line
        elsif ret_iva == 16
          importe_ret_linea = importe_iva
        end
      else
        importe_ret_linea = 0
      end
      suma_ret += importe_ret_linea


      ## Creando y poblando CFDI:CONCEPTO
      child_concepto = Nokogiri::XML::Node.new "cfdi:Concepto", xml
      child_concepto["ClaveProdServ"] = line[:clave_prod_serv].to_s
      child_concepto["NoIdentificacion"] = line[:sku].to_s
      child_concepto["ClaveUnidad"] = line[:clave_unidad].to_s
      child_concepto["Unidad"] = line[:unidad].to_s
      child_concepto["Descripcion"] = line[:descripcion].to_s
      child_concepto["Cantidad"] = cantidad.to_s
      child_concepto["ValorUnitario"] = valor_unitario.round(4).to_s
      child_concepto["Importe"] = subtotal_line.round(4).to_s
      child_concepto["ObjetoImp"] = "02"


      ## Creando cdfi:Impuestos para cada linea
      child_impuestos = Nokogiri::XML::Node.new "cfdi:Impuestos", xml

      ## Creando cfdi:Traslados para cada linea
      child_traslados = Nokogiri::XML::Node.new "cfdi:Traslados", xml


      child_traslado = Nokogiri::XML::Node.new "cfdi:Traslado", xml
      child_traslado["Impuesto"] = "002"
      child_traslado["TipoFactor"] = "Tasa"
      child_traslado["Base"] = subtotal_line.round(4).to_s

      if iva_id > 0
        tasa_cuota = (iva_id / 100)
        child_traslado["Importe"] = importe_iva.round(4).to_s
        child_traslado["TasaOCuota"] = sprintf("%.6f", tasa_cuota)
      else
        child_traslado["Importe"] = "0.00"
        child_traslado["TasaOCuota"] = "0.000000"
      end


      # Mezclando todo lo anterios
      child_traslados.add_child(child_traslado)
      child_impuestos.add_child(child_traslados)
      child_concepto.add_child(child_impuestos)
      conceptos.add_child(child_concepto)

      ## Creando cfdi:Retenciones para cada linea en caso de tener
      if ret_iva > 0
        child_retenciones = Nokogiri::XML::Node.new "cfdi:Retenciones", xml
        child_retencion = Nokogiri::XML::Node.new "cfdi:Retencion", xml
        child_retencion["Base"] = subtotal_line.round(4).to_s
        child_retencion["Impuesto"] = "002"
        child_retencion["TipoFactor"] = "Tasa"

        if ret_iva == 6
          child_retencion["TasaOCuota"] = "0.060000"
        elsif ret_iva == 16
          child_retencion["TasaOCuota"] = "0.160000"
        end

        child_retencion["Importe"] = importe_ret_linea.round(4).to_s

        child_retenciones.add_child(child_retencion)
        child_impuestos.add_child(child_retenciones)
      end
    end

    puts "------ Totales -----"
    puts "Total suma = #{suma_total.round(2)}"
    puts "SubTotal suma = #{subtotal.round(2)}"
    puts "Suma iva = #{suma_iva.round(2)}"
    puts "Suma restenciones = #{suma_ret.round(2)}"

    comprobante["Moneda"] = params.fetch(:moneda, "MXN")
    comprobante["SubTotal"] = subtotal.round(2).to_s


    ## Poblando cfdi:Impuestos
    impuestos["TotalImpuestosRetenidos"] = suma_ret.round(2).to_s if suma_ret > 0

    if suma_iva > 0
      impuestos["TotalImpuestosTrasladados"] = suma_iva.round(2).to_s
    else
      impuestos["TotalImpuestosTrasladados"] = "0.00"
    end


    ## filling default retencion info
    if suma_ret > 0
      retenciones = Nokogiri::XML::Node.new "cfdi:Retenciones", xml
      retencion_child = Nokogiri::XML::Node.new "cfdi:Retencion", xml
      retencion_child["Impuesto"] = "002"
      retencion_child["Importe"] = suma_ret.round(2).to_s
      # retencion_child['TipoFactor'] = "Tasa"

      retenciones.add_child(retencion_child)
      impuestos.add_child(retenciones)
      comprobante["Total"] = (suma_total - suma_ret).round(2).to_s
    else
      comprobante["Total"] = suma_total.round(2).to_s
    end


    ## filling traslado info
    traslado_child = Nokogiri::XML::Node.new "cfdi:Traslado", xml
    traslado_child["Impuesto"] = "002"
    traslado_child["TipoFactor"] = "Tasa"
    traslado_child["Base"] = subtotal.round(2)

    if suma_iva > 0
      traslado_child["Importe"] = suma_iva.round(2).to_s
      traslado_child["TasaOCuota"] = "0.160000"
    else
      traslado_child["Importe"] = "0.00"
      traslado_child["TasaOCuota"] = "0.000000"
    end

    traslados.add_child(traslado_child)
    impuestos.add_child(traslados)

    ## -----
    path = File.join(File.dirname(__FILE__), *%w[.. tmp])
    id = SecureRandom.hex

    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.write("#{path}/tmp_#{id}.xml", xml.to_xml)
    xml_path = "#{path}/tmp_#{id}.xml"
    cadena_path = File.join(File.dirname(__FILE__), *%w[cadena cadenaoriginal_4_0.xslt])

    # puts File.read(cadena_path)
    File.write("#{path}/pem_#{id}.pem", @pem)
    key_pem_url = "#{path}/pem_#{id}.pem"
    sello = %x(xsltproc #{cadena_path} #{xml_path} | openssl dgst -sha256 -sign #{key_pem_url} | openssl enc -base64 -A)
    comprobante["Sello"] = sello

    File.delete("#{xml_path}")
    File.delete("#{key_pem_url}")

    ## TODO
    # Generar la cadena original usando Nokogiri para la transformación XSLT
    # cadena_path = File.join(File.dirname(__FILE__), "cadena", "cadenaoriginal_4_0.xslt")
    # xslt = Nokogiri::XSLT(File.read(cadena_path))
    # cadena_original = xslt.transform(xml).to_s

    # # Cargar la llave privada desde la variable de instancia @pem
    # private_key = OpenSSL::PKey.read(@pem)

    # # Firmar la cadena original con SHA256
    # signature = private_key.sign(OpenSSL::Digest::SHA256.new, cadena_original)

    # # Codificar la firma en Base64
    # sello = Base64.strict_encode64(signature)

    # # Asignar el sello al comprobante
    # comprobante["Sello"] = sello

    puts "---- Fdis: comprobante sin timbrar ------"
    puts xml.to_xml
    puts "-------------------------"

    base64_xml = Base64.encode64(xml.to_xml)

    # haciendo llamada a API
    uri = URI("#{UrlPro}/Timbrar40")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump({
      "testMode": !@production,
      "idServicio": @id_servicio,
      "base64XmlFile": base64_xml
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    json_response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    puts "---- Fdis: request"
    puts "-- body: #{request.body} --"

    puts "---- Fdis: Respuesta"
    puts "-- Codigo: #{json_response.code} --"
    puts "-- Mensaje: #{json_response.message} --"
    puts "-- Body: "
    p json_response.body
    puts "-------------------------"

    response = JSON.parse(json_response.body)

    case json_response
    when Net::HTTPSuccess, Net::HTTPRedirection
      if response["success"] == true
        ns = {
          "cfdi" => "http://www.sat.gob.mx/cfd/4",
          "tfd"  => "http://www.sat.gob.mx/TimbreFiscalDigital"
        }

        doc = Nokogiri::XML(Base64.decode64(response["base64XmlFile"]))
        timbre = doc.at_xpath("//tfd:TimbreFiscalDigital", ns)

        response = {
          status: 200,
          message_error: "",
          xml: doc.to_xml,
          uuid: timbre["UUID"],
          fecha_timbrado: timbre["FechaTimbrado"],
          sello_cfd: timbre["SelloCFD"],
          sello_sat: timbre["SelloSAT"],
          no_certificado_sat: timbre["NoCertificadoSAT"]
        }
        response
      else
        response = {
          status: 400,
          message_error: "Error: #{response['errorMessages']}",
          xml: "",
          uuid: "",
          fecha_timbrado: "",
          sello_cfd: "",
          sello_sat: "",
          no_certificado_sat: ""
        }
        response

      end
    else
      response = {
        status: json_response.code,
        message_error: "Error: #{response['errorMessages']}",
        xml: "",
        uuid: "",
        fecha_timbrado: "",
        sello_cfd: "",
        sello_sat: "",
        no_certificado_sat: ""
      }
      response

    end
  end
end
