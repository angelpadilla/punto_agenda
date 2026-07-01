class Admin::TicketMessagesController < AdminController
  before_action :set_ticket

  def create
    @message = @ticket.ticket_messages.new(message_params)
    @message.sender = current_admin

    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_ticket_message",
            partial: "admin/tickets/reply_form",
            locals: { ticket: @ticket, message: TicketMessage.new }
          )
        end
        format.html { redirect_to admin_ticket_path(@ticket), notice: "Mensaje enviado." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_ticket_message",
            partial: "admin/tickets/reply_form",
            locals: { ticket: @ticket, message: @message }
          )
        end
        format.html { redirect_to admin_ticket_path(@ticket), alert: "Error al enviar mensaje." }
      end
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:admin_ticket_id])
  end

  def message_params
    params.require(:ticket_message).permit(:body)
  end
end
