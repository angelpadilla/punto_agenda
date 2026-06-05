class ApplicationController < ActionController::Base
  include Pagy::Method
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_vars

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    redirect_to root_path, notice: "Objeto no encontrado"
  end

  def after_sign_out_path_for(model)
    root_path
  end

  def set_vars
    @setting = Setting.first || nil
  end

  def after_sign_in_path_for(model)
    puts "----- after_sign_in_path_for #{model.inspect} -----"
    if model.model_name.name == "User"
      puts "***1"
      user_panel_home_path
    elsif model.model_name.name == "Admin"
      puts "***2"
      admin_panel_home_path
    else
      puts "***3"
      super
    end
  end
end
