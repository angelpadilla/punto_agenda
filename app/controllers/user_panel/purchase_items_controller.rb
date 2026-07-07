class UserPanel::PurchaseItemsController < UserPanelController
  def add_item

    ##validations
    if !params[:purchase_id].present? or !params[:item_id].present? or !params[:cantidad].present?
      return redirect_back(fallback_location: new_purchase_path, alert: "Parametros incompletos")
    end

    @purchase = Purchase.find(params[:purchase_id])
    @item = Item.find(params[:item_id])
    @show_cart_button = params[:source] != "resumen"
    precio = params[:precio].to_f
    cantidad = params[:cantidad].to_f
    
    respond_to do |format|
      @purchase.add_item(@item, cantidad, precio)
      @purchase.save(validate: false)
      format.turbo_stream
    end
  end

  def down_item
    @purchase = Purchase.find(params[:purchase_id])
    @show_cart_button = params[:source] != 'resumen'
    line_id = params[:line_id]
    cantidad = params[:cantidad].to_f

    respond_to do |format|
      @purchase.down_item(line_id, cantidad)
      @purchase.save(validate: false)
      
      format.turbo_stream
    end
  end

  def remove_item
    @purchase = Purchase.find(params[:purchase_id])
    @show_cart_button = params[:source] != 'resumen'
    line_id = params[:line_id]
    @purchase.destroy_item(line_id)
    @purchase.save(validate: false)

    respond_to do |format|
      
      format.turbo_stream
    end
  end

  def clear_items
    @purchase = Purchase.find(params[:purchase_id])
    @show_cart_button = params[:source] != 'resumen'
    respond_to do |format|
      @purchase.purchase_items.destroy_all
      @purchase.save(validate: false)
      format.html { redirect_back(fallback_location: new_purchase_path, notice: "Todos los items han sido eliminados del pedido.") }
      format.turbo_stream
    end
  end

  def add_gasto_item
    @purchase = Purchase.find(params[:purchase_id])
    nombre = params[:nombre].to_s.strip
    cantidad = params[:cantidad].to_f
    precio = params[:precio].to_f
    iva = params[:iva].to_f

    if nombre.blank? || cantidad <= 0 || precio <= 0
      return redirect_back(fallback_location: new_gasto_purchases_path, alert: "Todos los campos son requeridos")
    end

    @purchase.purchase_items.create!(
      nombre: nombre,
      cantidad: cantidad,
      precio: precio,
      iva: iva,
      item_id: nil
    )
    @purchase.save(validate: false)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def remove_gasto_item
    @purchase = Purchase.find(params[:purchase_id])
    line_id = params[:line_id]
    @purchase.destroy_item(line_id)
    @purchase.save(validate: false)

    respond_to do |format|
      format.turbo_stream
    end
  end

end