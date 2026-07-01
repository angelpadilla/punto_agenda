class Admin::TicketsController < AdminController
  before_action :set_ticket, only: %i[show edit update]

  def index
    tickets = Ticket.default.includes(:corp, :admin)

    @q = tickets.ransack(params[:q])
    @pagy, @tickets = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
    @ticket_messages = @ticket.ticket_messages.includes(:sender).order(:created_at)
    @message = TicketMessage.new
  end

  def edit
  end

  def update
    if @ticket.update(ticket_params)
      redirect_to admin_ticket_path(@ticket), notice: "Ticket actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:status, :priority, :category, :admin_id)
  end
end
