class AdminController < ApplicationController
  layout "admin"
  before_action :authenticate_admin!
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def home
    noww = Time.current
    @total_corps = Corp.count
    @total_users = User.count
    # @total_events = Event.count
    # @total_items  = Item.count

    # Bills el dia de hoy
    @bills_today = Bill.pagado.where(created_at: noww.beginning_of_day..noww.end_of_day).sum(:total)
    @bills_month = Bill.pagado.where(created_at: noww.beginning_of_month..noww.end_of_month).sum(:total)
  end

  private

  def record_not_found
    redirect_to admin_panel_home_path, alert: "Ups, Objeto no fue encontrado."
  end
end
