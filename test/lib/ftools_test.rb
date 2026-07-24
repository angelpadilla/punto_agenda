require "test_helper"

class FtoolsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  class FakeBill
    attr_accessor :folio, :forma_pago, :corp, :line_items, :xml, :sat_uuid,
                  :sat_timbre_fecha, :sat_cfdi, :sat_sello, :sat_sello_emisor,
                  :sat_serial, :tipo, :error

    def initialize(folio:, forma_pago:, corp:, line_items:)
      @folio = folio
      @forma_pago = forma_pago
      @corp = corp
      @line_items = line_items
    end

    def deposits
      []
    end

    def credito?
      false
    end

    def save
      true
    end
  end

  test "timbra_bill asigna xml al bill y guarda datos SAT en timbrado exitoso" do
    setting = Struct.new(:cp).new("01000")
    corp = Struct.new(:cp, :rfc, :razon, :regimen).new("01000", "AAA010101AAA", "Corp Demo", "601")
    line = Struct.new(:cantidad, :nombre, :precio_descuento, :iva).new(1, "Servicio demo", 100.0, 16.0)
    bill = FakeBill.new(folio: "B-100", forma_pago: "efectivo", corp: corp, line_items: [ line ])

    factura_response = {
      status: 200,
      xml: "<xml>ok</xml>",
      uuid: "uuid-123",
      fecha_timbrado: "2026-01-01T10:00:00",
      sello_cfd: "sello-cfd",
      sello_sat: "sello-sat",
      no_certificado_sat: "cert-sat"
    }

    factura = Object.new
    factura.define_singleton_method(:serial) { "serial-123" }
    factura.define_singleton_method(:timbra_doc) { |_params| factura_response }

    original_setting_find = Setting.method(:find)
    original_bill_forma_pagos = Bill.method(:forma_pagos)
    original_ftools_set_bill = Ftools.method(:set_bill)

    begin
      Setting.define_singleton_method(:find) { |_id| setting }
      Bill.define_singleton_method(:forma_pagos) { { "efectivo" => "01" } }
      Ftools.define_singleton_method(:set_bill) { |_setting| factura }

      result = Ftools.timbra_bill(bill, "G03")
    ensure
      Setting.define_singleton_method(:find, original_setting_find)
      Bill.define_singleton_method(:forma_pagos, original_bill_forma_pagos)
      Ftools.define_singleton_method(:set_bill, original_ftools_set_bill)
    end

    assert_equal true, result
    assert_equal "<xml>ok</xml>", bill.xml
    assert_equal "uuid-123", bill.sat_uuid
    assert_equal "2026-01-01T10:00:00", bill.sat_timbre_fecha
    assert_equal "sello-cfd", bill.sat_cfdi
    assert_equal "sello-sat", bill.sat_sello
    assert_equal "cert-sat", bill.sat_sello_emisor
    assert_equal "serial-123", bill.sat_serial
    assert_equal "factura", bill.tipo
    assert_nil bill.error
  end
end
