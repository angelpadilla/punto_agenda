class EventMailer < ApplicationMailer
  def send_event
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} cita agendada")
  end

  def send_event_today
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} recordatorio de cita HOY")
  end

  def sent_event_confirmation
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} tu cita ha sido confirmada")
  end

  def sent_event_ausencia
    @event = params[:event]
    @corp = @event.corp
    email = params[:email]

    mail(to: email, subject: "#{@corp.name} lamentamos que no hayas podido asistir a tu cita")
  end
end