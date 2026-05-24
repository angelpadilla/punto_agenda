class BillPdf < Prawn::Document
  def initialize(bill)
    super(top_margin: 20)
    @bill = bill
    header
    bill_details
  end

  def header
    text "Factura", size: 30, style: :bold
    move_down 20
  end

  def bill_details
    text "Folio: #{@bill.folio}", size: 15
    text "Tipo: #{@bill.tipo}", size: 15
    text "Forma de Pago: #{@bill.forma_pago}", size: 15
    text "Status de Pago: #{@bill.status_pago}", size: 15
    move_down 20

    text "Items:", size: 18, style: :bold
    @bill.bill_items.each do |item|
      text "- #{item.nombre}: $#{item.total}", size: 12
    end
  end
end