module CorpCan
  # extend ActiveSupport::Concern

  def stop_corp_basico
    if @corp.basico?
      redirect_to user_panel_home_path, alert: "Tu plan actual no tiene acceso a esta sección. Por favor, contacta al propietario o al soporte para más información."
    end
  end

  def stop_corp_plus
    if @corp.plus?
      redirect_to user_panel_home_path, alert: "Tu plan actual no tiene acceso a esta sección. Por favor, contacta al propietario o al soporte para más información."
    end
  end
end
