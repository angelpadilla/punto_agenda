class UserPanel::BillsController < ApplicationController
  before_action :set_bill, only: %i[ show  ]
  def index
    bills = @corp.bills

    @q = bills.ransack(params[:q])
    @pagy, @bills = pagy(@q.result(distinct: true), limit: 10)
  end

  def show
  end

  private

  def set_bill
    @bill = @corp.bills.find(params[:id])
  end
end