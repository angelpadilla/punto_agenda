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
    redirect_to user_panel_home_path, alert: "El item que intentas ver no fue encontrado."
  end

  private

  def set_globals
    @user = current_user
    @corp = @user.corp

    if session[:carrito_id]
      @carrito = Order.find_by(id: session[:carrito_id])
    end

    unless @carrito
      @carrito = Order.create!(user_id: current_user.id, corp_id: @corp.id)
      session[:carrito_id] = @carrito.id
    end
  end
end
