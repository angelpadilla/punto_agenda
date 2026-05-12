class UserPanel::CorpController < UserPanelController
  def landing
  end
  def show
  end

  def edit
  end

  def update
    if @corp.update(corp_params)
      redirect_to user_corp_path, notice: "Información de empresa actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def corp_params
    permitted = params.require(:corp).permit(
      :calendar,
      :slot_duration,
      :calle,
      :ciudad,
      :colonia,
      :cp,
      :estado,
      :facebook_url,
      :instagram_url,
      :key_pass,
      :localidad,
      :name,
      :num_ext,
      :num_int,
      :online_payments,
      :phone,
      :public_site,
      :razon,
      :regimen,
      :rfc,
      :text_cotizacion,
      :text_factura,
      :text_remision,
      :tiktok_url,
      :timbres,
      :tipo_negocio,
      :whatsapp,
      :facturacion,
      :key,
      :cer,
      :logo
    ).to_h
    bh = params.dig(:corp, :business_hours)
    permitted["business_hours"] = bh.to_unsafe_h if bh.present?
    permitted
  end
end
