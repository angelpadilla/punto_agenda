class AdminController < ApplicationController
  layout 'admin'
  before_action :authenticate_admin!
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def home
    @total_corps = Corp.count
    @total_users = User.count
    @total_events = Event.count
    @total_items  = Item.count
    @total_orders = Order.count
  end

  private

  def record_not_found
    redirect_to admin_panel_home_path, alert: "Ups, Objeto no fue encontrado."
  end
end
