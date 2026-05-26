class UserPanel::LineItemsController < UserPanelController
  def add_item
    @order = Order.find(params[:order_id])
    item = Item.find(params[:item_id])
    precio = params[:precio].to_f
    cantidad = params[:cantidad].to_f
    descuento = params[:descuento].to_f

    line = @order.line_items.where(item_id: item.id).first

    # si el stock es nil, se considera que es ilimitado, por lo tanto no se hace la validación de stock
    if !item.stock.nil?
      if item.stock <= 0
        return redirect_back(fallback_location: new_order_path, alert: "Item sin inventario disponible")
      end

      if line
        disponible = item.stock - line.cantidad - cantidad
      else
        disponible = item.stock - cantidad
      end

      respond_to do |format|
        if disponible >= 0
          @order.add_item(item, cantidad, precio, descuento)
          @order.save(validate: false)

          if @order.pre_factura?
            # rebajamos inventario
            @order.line_items.each do |line|
              item = line.item
              if !item.stock.nil?
                item.stock -= cantidad
                item.save
              end
            end
          end
          format.turbo_stream
        else
          @error_message = "No hay suficiente inventario disponible para agregar #{cantidad} unidades de #{item.name}. Solo quedan #{disponible} disponibles."
          # format.turbo_stream {
          #   render turbo_stream: turbo_stream.update("line_item_errors", partial: "user_panel/orders/line_item_errors", locals: { error_message: @error_message })
          # }
          format.turbo_stream
        end
      end
    else
      respond_to do |format|
        @order.add_item(item, cantidad, precio, descuento)
        @order.save(validate: false)
        format.turbo_stream
      end
    end
  end

  def remove_item
    @order = Order.find(params[:order_id])
    line_id = params[:line_id]
    cantidad = params[:cantidad].to_f

    respond_to do |format|
      @order.down_item(line_id, cantidad)
      @order.save(validate: false)
      if @order.pre_factura?
        # devolvemos inventario
        @order.line_items.each do |line|
          item = line.item
          if !item.stock.nil?
            item.stock += cantidad
            item.save
          end
        end
      end
      format.turbo_stream
    end
  end

  def clear_items
    @order = Order.find(params[:order_id])
    respond_to do |format|
      @order.line_items.destroy_all
      @order.save(validate: false)
      format.turbo_stream
    end
  end


  private

  def line_item_params
    params.require(:line_item).permit(:item_id, :quantity)
  end
end
