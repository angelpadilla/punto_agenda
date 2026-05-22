class UserPanel::BillsController < UserPanelController
  before_action :set_bill, only: %i[ show  ]
  def index
    bills = @corp.bills.default

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
