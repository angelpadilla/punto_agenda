class Admin::TrafficVisitsController < AdminController
  def index
    @q = TrafficVisit.ransack(params[:q])
    @result = @q.result(distinct: true)
    @pagy, @traffic_visits = pagy(@result.order(created_at: :desc), limit: 25)
  end
end
