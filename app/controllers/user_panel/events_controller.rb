class UserPanel::EventsController < UserPanelController
  before_action :set_event, only: %i[ show edit update destroy marcar_asistencia marcar_ausencia confirmar cancelar ]

  def index
    @customers = @corp.customers.default
    @users = @corp.users.default
    events = @corp.events.order("hora_inicio DESC", "created_at DESC")
    @por_confirmar = events.por_confirmar.count

    @q = events.ransack(params[:q])
    @pagy, @events = pagy(@q.result(distinct: true), limit: 10)
  end

  def monthly
    @customers = @corp.customers.default
    @users = @corp.users.default
    @events = @corp.events.default
    @por_confirmar = @events.por_confirmar.count
    @q = @events.ransack(params[:q])
  end

  def weekly
    @customers = @corp.customers.default
    @users = @corp.users.default
    @events = @corp.events.default
    @por_confirmar = @events.por_confirmar.count
    @q = @events.ransack(params[:q])
  end


  def slot_agents
    date = Date.parse(params[:dia])
    info = @corp.available_slots_for_day(date)
    if info
      data = info[:slots].each_with_object({}) do |slot, h|
        # IDs de agentes no disponibles (ocupados + fuera de horario)
        unavailable = slot[:booked_agents].map(&:id) + slot[:non_working_agents].map(&:id)
        h[slot[:range]] = unavailable.uniq
      end
      render json: data
    else
      render json: {}
    end
  rescue ArgumentError, TypeError
    render json: {}, status: :bad_request
  end

  def show
  end

  def new
    if params[:dia].present? && Date.parse(params[:dia]) < Date.today
      redirect_to new_event_path(params.permit(:customer_id, :slot).except(:dia, :slot))
      return
    end

    @event = Event.new
  rescue ArgumentError
    redirect_to new_event_path
  end

  def edit
    redirect_back(fallback_location: events_path, alert: "Solo se pueden editar los eventos status: agendados.") unless @event.agendado?
  end

  def create
    @event = @corp.events.new(event_params)

    ## validaciones extras
    unless params[:event][:dia].present?
      @event.errors.add(:dia, "Día del evento es requerido")
      return render :new, status: :unprocessable_entity
    end

    unless params[:event][:slot].present?
      @event.errors.add(:slot, "El horario (slot) es requerido")
      return render :new, status: :unprocessable_entity
    end


    unless params[:event][:user_id].present?
      @event.user_id = current_user.id
    end

    fecha = params[:event][:dia]
    slot  = params[:event][:slot]  # "09:00|11:00"
    recurrence_rule     = params[:event][:recurrence_rule].presence
    recurrence_ends_on  = params[:event][:recurrence_ends_on].presence

    if fecha.present? && slot.present?
      inicio, fin = slot.split("|")
      tz = ActiveSupport::TimeZone["America/Mexico_City"]
      @event.hora_inicio = tz.parse("#{fecha} #{inicio}") if inicio.present?
      @event.hora_final  = tz.parse("#{fecha} #{fin}")   if fin.present?
    end

    # ── Recurrencia ───────────────────────────────────────────────────
    if recurrence_rule.present? && recurrence_ends_on.present? &&
      Event::RECURRENCE_RULES.include?(recurrence_rule)

      fechas = Event.generar_fechas(fecha, recurrence_rule, recurrence_ends_on)
      rid    = SecureRandom.alphanumeric(12)
      tz     = ActiveSupport::TimeZone["America/Mexico_City"]
      inicio_t, fin_t = slot.to_s.split("|")
      saved_events = []

      fechas.each_with_index do |f, i|
        ev = @corp.events.new(event_params.merge(
          hora_inicio:       tz.parse("#{f} #{inicio_t}"),
          hora_final:        tz.parse("#{f} #{fin_t}"),
          recurrence_id:     rid,
          recurrence_rule:   recurrence_rule,
          recurrence_ends_on: recurrence_ends_on,
          recurrence_index:  i
        ))
        ev.user_id ||= current_user.id
        saved_events << ev if ev.save
      end

      first = saved_events.first
      return respond_to do |format|
        if saved_events.any?
          format.html { redirect_to weekly_events_path(start_date: first.hora_inicio.strftime("%Y-%m-%d")),
                          notice: "Serie de #{saved_events.size} evento(s) creada correctamente." }
          format.json { render json: saved_events, status: :created }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    end
    # ─────────────────────────────────────────────────────────────────

    respond_to do |format|
      if @event.save
        start_date = @event.hora_inicio.strftime("%Y-%m-%d")
        if @corp.sms > 0
          # # enviar sms si el corp tiene creditos de sms
          MessageEvent.create!(
            tipo: :sms,
            corp: @corp,
            eventeable: @event,
            customer: @event.customer,
            to: @event.customer.tel,
            prefix: @event.customer.tel_prefix,
            body: "Tu evento programado: #{@event.title}\nFecha y hora: #{@event.hora_inicio.strftime("%d/%m/%Y %I:%M %p")}\nGracias por tu preferencia en #{@corp.name}!"
          )

        end

        # enviar email de confirmación de nuevo evento
        MessageEvent.create!(
          tipo: :email,
          corp: @corp,
          eventeable: @event,
          customer: @event.customer,
          to: @event.customer.email.strip,
        )

        format.html { redirect_to weekly_events_path(start_date: start_date), notice: "Evento creado y notificado al cliente." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def marcar_asistencia
    ## cambiar el estado del evento a completado
    customer = @event.customer
    respond_to do |format|
      if @event.agendado?
        @event.update(status: :completado)
        customer.update(success_events: customer.success_events + 1) if customer
        format.html { redirect_back fallback_location: events_path, notice: "Evento marcado como asistida.", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { redirect_back fallback_location: events_path, alert: "Solo se pueden marcar como asistida los eventos agendados.", status: :see_other }
        format.json { render json: { error: "Solo se pueden marcar como asistida los eventos agendados." }, status: :unprocessable_entity }
      end
    end
  end

  def marcar_ausencia
    ## cambiar el estado del evento a ausencia
    customer = @event.customer
    respond_to do |format|
      if @event.agendado?
        @event.update(status: :ausencia)
        customer.update(failed_events: customer.failed_events + 1) if customer
        EventMailer.with(event: @event, email: @event.customer.email).sent_event_ausencia.deliver_later
        format.html { redirect_back fallback_location: events_path, notice: "Evento marcado como ausente y notificado al cliente por email", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { redirect_back fallback_location: events_path, alert: "Solo se pueden marcar como ausente los eventos en proceso.", status: :see_other }
        format.json { render json: { error: "Solo se pueden marcar como ausente los eventos en proceso." }, status: :unprocessable_entity }
      end
    end
  end

  def confirmar
    # validar que el evento esté en estado por_confirmar
    return redirect_back(fallback_location: events_path, alert: "Solo se pueden confirmar los eventos por confirmar.") if !@event.por_confirmar?

    @event.update(status: :agendado)
    # enviar email de confirmación al cliente
    EventMailer.with(event: @event, email: @event.customer.email).sent_event_confirmation.deliver_later
    if @corp.sms > 0
      # enviar sms de confirmación al cliente
      MessageEvent.create!(
        tipo: :sms,
        corp: @corp,
        eventeable: @event,
        customer: @event.customer,
        to: @event.customer.tel,
        prefix: @event.customer.tel_prefix,
        body: "Tu evento ha sido confirmado: #{@event.title}\nFecha y hora: #{@event.hora_inicio.strftime("%d/%m/%Y %I:%M %p")}\nGracias por tu preferencia en #{@corp.name}!"
      )
    end

    solapados = @corp.events
                  .por_confirmar
                  .where.not(id: @event.id)
                  .where("hora_inicio < ? AND hora_final > ?", @event.hora_final, @event.hora_inicio)

    if solapados.any?
      solapados.each do |ev|
        ev.update(status: :cancelado, motivo_cancelacion: "Evento cancelado automáticamente: otro cliente fue confirmado en este horario.")
        EventMailer.with(event: ev, email: ev.customer.email).send_event_cancelation.deliver_later
      end
    end

    msg = "Evento confirmado y notificado al cliente."
    msg += " #{solapados.size} evento(s) en conflicto cancelados automáticamente." if solapados.any?
    redirect_back(fallback_location: events_path, notice: msg, status: :see_other)
  end

  def cancelar
    motivo = params[:motivo]
    # validar que el evento no esté ya cancelado
    return redirect_back(fallback_location: events_path, alert: "El evento ya está cancelado.") if @event.cancelado?
    return redirect_back(fallback_location: events_path, alert: "Motivo de cancelación es requerido.") if !motivo.present?

    # EventMailer.with(event: @event, email: @event.customer.email).send_event_cancelation.deliver_later
    @event.update(status: :cancelado, motivo_cancelacion: motivo)
    redirect_back(fallback_location: events_path, notice: "Evento cancelado y notificado al cliente por email.", status: :see_other)
  end

  def cancelar_recurrence
    motivo = params[:motivo]
    recurrence_id = params[:recurrence_id]
    # validar que el evento no esté ya cancelado
    return redirect_back(fallback_location: events_path, alert: "Motivo de cancelación es requerido.") if !motivo.present?
    return redirect_back(fallback_location: events_path, alert: "ID de recurrencia es requerido.") if !recurrence_id.present?

    events = @corp.events.serie(recurrence_id)
    events.each do |ev|
      ev.update(status: :cancelado, motivo_cancelacion: motivo)
    end
    redirect_back(fallback_location: events_path, notice: "Serie de eventos cancelada.", status: :see_other)
  end


  def update
    @event.assign_attributes(event_params)
    ## validaciones extras
    unless params[:event][:dia].present?
      @event.errors.add(:dia, "Día del evento es requerido")
      return render :edit, status: :unprocessable_entity
    end

    unless params[:event][:slot].present?
      @event.errors.add(:slot, "El horario (slot) es requerido")
      return render :edit, status: :unprocessable_entity
    end

    unless params[:event][:user_id].present?
      @event.user_id = current_user.id
    end

    fecha = params[:event][:dia]
    slot  = params[:event][:slot]

    if fecha.present? && slot.present?
      inicio, fin = slot.split("|")
      tz = ActiveSupport::TimeZone["America/Mexico_City"]
      @event.hora_inicio = tz.parse("#{fecha} #{inicio}") if inicio.present?
      @event.hora_final  = tz.parse("#{fecha} #{fin}")   if fin.present?
    end


    respond_to do |format|
      if @event.save
        format.html { redirect_to events_path, notice: "Evento actualizado.", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: events_path, notice: "Evento eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def send_sms
    ## validations
    return redirect_back(fallback_location: user_panel_home_path, alert: "Folio no proporcionado") if !params[:folio].present?
    return redirect_back(fallback_location: user_panel_home_path, alert: "Número de teléfono incorrecto") if !params[:tel].present? or !params[:tel_prefix].present?

    @event = @corp.events.find_by(folio: params[:folio])

    redirect_back(fallback_location: user_panel_home_path, alert: "Objeto no encontrado") if !@event

    prefix = params[:tel_prefix].strip
    tel = params[:tel].strip

    ## SMS
    response = SmsService.sms(to: tel, code: prefix, body: "Tu evento programado: #{@event.title}\nFecha y hora: #{@event.hora_inicio.strftime("%d/%m/%Y %I:%M %p")}\nGracias por tu preferencia en #{@corp.name}!")

    puts " --- Enviando SMS a #{tel}"
    puts response

    if response[:success]
      redirect_to event_path(@event), notice: "SMS enviado exitosamente."
    else
      redirect_to event_path(@event), alert: "Error al enviar SMS: #{response[:message]}"
    end
  end

  def send_email
    ## validations
    if !params[:folio].present? or !params[:email].present?
      return redirect_back(fallback_location: user_panel_home_path, alert: "Folio de venta o email no proporcionado")
    end

    event = @corp.events.find_by(folio: params[:folio])
    redirect_back(fallback_location: user_panel_home_path, alert: "Evento no encontrado") if !event

    email = params[:email]

    # if event is today, send email with different subject
    if event.hora_inicio.to_date == Date.current
      EventMailer.with(event: event, email: email).send_event_today.deliver_later
    else
      EventMailer.with(event: event, email: email).send_event.deliver_later
    end

    redirect_back(fallback_location: event_path(event), notice: "Email del evento enviado a #{email}")
  end

  private

  def set_event
    @event = @corp.events.find(params[:id])
  end

  def event_params
    params.expect(event: [
      :title,
      :body,
      :customer_id,
      :user_id,
      :recurrence_rule,
      :recurrence_ends_on
    ])
  end
end
