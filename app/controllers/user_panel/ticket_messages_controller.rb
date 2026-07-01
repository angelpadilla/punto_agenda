class UserPanel::TicketMessagesController < UserPanelController
  before_action :set_ticket
  before_action :ensure_ticket_open

  def create
    @message = @ticket.ticket_messages.new(message_params)
    @message.sender = current_user

    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_ticket_message",
            partial: "user_panel/tickets/reply_form",
            locals: { ticket: @ticket, message: TicketMessage.new }
          )
        end
        format.html { redirect_to user_ticket_path(@ticket), notice: "Mensaje enviado." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_ticket_message",
            partial: "user_panel/tickets/reply_form",
            locals: { ticket: @ticket, message: @message }
          )
        end
        format.html { redirect_to user_ticket_path(@ticket), alert: "Error al enviar mensaje." }
      end
    end
  end

  private

  def set_ticket
    @ticket = @corp.tickets.find(params[:user_ticket_id])
  end

  def ensure_ticket_open
    unless @ticket.abierto_para_mensajes?
      redirect_to user_ticket_path(@ticket), alert: "Este ticket está #{@ticket.status.to_s.humanize.downcase}. No se pueden enviar más mensajes."
    end
  end

  def message_params
    params.require(:ticket_message).permit(:body)
  end
end
