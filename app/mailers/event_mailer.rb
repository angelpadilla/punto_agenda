class EventMailer < ApplicationMailer
  def send_event
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} cita #{@event.folio}")
  end

  def send_event_today
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} recordatorio de cita #{@event.folio} hoy")
  end
end