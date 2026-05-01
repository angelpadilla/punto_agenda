class UserPanelController < ApplicationController
  layout "user"
  before_action :authenticate_user!
  before_action :set_globals

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def home
  end

  def landing_purchases
  end

  def landing_orders
  end

  def record_not_found
    redirect_to user_panel_home_path, alert: "Ups, Objeto no fue encontrado."
  end

  private

  def set_globals
    @user = current_user
    @corp = @user.corp

    if session[:carrito_id]
      @carrito = Order.find_by(id: session[:carrito_id])
    end
  end
end
