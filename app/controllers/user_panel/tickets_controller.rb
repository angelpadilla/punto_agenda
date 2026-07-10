class UserPanel::TicketsController < UserPanelController
  before_action :set_ticket, only: %i[show marcar_resuelto]

  def index
    tickets = @corp.tickets.default

    @q = tickets.ransack(params[:q])
    @pagy, @tickets = pagy(@q.result(distinct: true), limit: 15)
  end

  def show
    @ticket_messages = @ticket.ticket_messages.includes(:sender).order(:created_at)
    @message = TicketMessage.new
  end

  def new
    @ticket = @corp.tickets.new
  end

  def create
    @ticket = @corp.tickets.new(ticket_params)
    if @corp.basico?
      @ticket.priority = :baja
    elsif @corp.plus?
      @ticket.priority = :media
    else
      @ticket.priority = :alta
    end

    if @ticket.save
      Gtools.telegram_noti(message: "Ticket creado:\nID: #{@ticket.id}\nCorp: #{@corp.sku}-#{@corp.id}")
      redirect_to user_ticket_path(@ticket), notice: "Ticket creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def marcar_resuelto
    @ticket.status = :resuelto
    @ticket.nota_admin = "Ticket marcado como resuelto por #{@userr.email}, #{Time.current.strftime('%d %b %I:%M %p')}"
    if @ticket.save
      redirect_to user_ticket_path(@ticket), notice: "Ticket marcado como resuelto."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_ticket
    @ticket = @corp.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :category)
  end
end
