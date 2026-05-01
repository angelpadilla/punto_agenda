class InventarioPublicoPdf < Prawn::Document
  def initialize(items:)
    super(top_margin: 20)
    @setting = Setting.first
    @items = items
    @timee = Time.current.in_time_zone("America/Mexico_City")
    @fontsize = 10
    font_size @fontsize

    head
    items_table
  end

  def head
    if @setting.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@setting.logo.key)
      image(logo_path, width: 200)
      move_down 10
    end

    text "LISTA DE PRECIOS PUBLICO GENERAL #{@timee.strftime("%d/%m/%Y")}", size: (@fontsize + 4), style: :bold
    move_down 10
    stroke_horizontal_rule
    move_down 10
  end

  def items_table
    table item_rows, width: bounds.width do
      row(0).font_style = :bold
      self.header = true
      self.row_colors = [ "DDDDDD", "FFFFFF" ]
      self.cell_style = { size: @fontsize, borders: [], padding: 1 }
    end
  end

  def item_rows
    [ [ "Existencia", "Medida", "Marca", "Modelo", "Precio" ] ] +
      @items.map do |item|
        alto = item.alto
        formatted_alto =
          if alto.nil?
            ""
          else
            af = alto.to_f
            af == af.to_i ? af.to_i.to_s : sprintf("%g", af)
          end

        [
          item.stokk.to_i,
          "#{item.ancho.to_i}/#{formatted_alto}R#{item.diametro.to_i}",
          item.brand&.name&.upcase,
          item.name.upcase,
          item.price ? "$ #{item.price.round(1)}" : "-"
        ]
      end
  end

  private

  def number_to_currency(number)
    ActionController::Base.helpers.number_to_currency(number)
  end
end
