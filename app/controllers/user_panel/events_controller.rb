class UserPanel::EventsController < UserPanelController
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    events = @corp.events.default

    respond_to do |format|
      format.html do
        @q = events.ransack(params[:q])
        @pagy, @events = pagy(@q.result(distinct: true), limit: 10)
      end
      format.json do
        range_start = Time.zone.parse(params[:start]) if params[:start].present?
        range_end   = Time.zone.parse(params[:end])   if params[:end].present?

        scoped = events
        scoped = scoped.where("hora_inicio >= ?", range_start) if range_start
        scoped = scoped.where("hora_inicio <= ?", range_end)   if range_end

        render json: scoped.map { |e|
          {
            id: e.id,
            title: e.title,
            start: e.hora_inicio&.iso8601,
            end: e.hora_final&.iso8601,
            url: event_path(e),
            classNames: [ "fc-event-#{e.status}" ],
            extendedProps: {
              status: e.status,
              customer: e.customer&.razon&.titleize,
              customer_tel: e.customer&.tel_prefix.to_s + e.customer&.tel.to_s,
              agente: e.user&.full_name,
              body: e.body.presence,
              edit_url: edit_event_path(e),
              show_url: event_path(e),
              marcar_asistencia_url: marcar_asistencia_events_path(id: e),
              marcar_ausencia_url: marcar_ausencia_events_path(id: e)
            }
          }
        }
      end
    end
  end

  def monthly
    @events = @corp.events.indexx

    @q = @events.ransack(params[:q])
  end
  def weekly
    @events = @corp.events.indexx

    @q = @events.ransack(params[:q])
  end

  def daily
    events = @corp.events
    @events = events.today

    @q = events.ransack(params[:q])
  end

  def show
  end

  def new
    if params[:customer_id].present?
      @customer = @corp.customers.find(params[:customer_id])
      @event = Event.new(customer: @customer)
    else
      @event = Event.new
    end
  end

  def edit
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

    if fecha.present? && slot.present?
      inicio, fin = slot.split("|")
      tz = ActiveSupport::TimeZone["America/Mexico_City"]
      @event.hora_inicio = tz.parse("#{fecha} #{inicio}") if inicio.present?
      @event.hora_final  = tz.parse("#{fecha} #{fin}")   if fin.present?
    end

    ## validar que un evento no se repita en el mismo rango de tiempo en la misma Corp
    # if Event.where(corp_id: @event.corp_id).where("hora_inicio < ? AND hora_final > ?", @event.hora_final, @event.hora_inicio).exists?
    #   @event.errors.add(:hora_inicio, "Ya existe un evento en ese rango de tiempo")
    #   return render :new, status: :unprocessable_entity
    # end

    respond_to do |format|
      if @event.save
        format.html { redirect_to events_path, notice: "Evento creado." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def marcar_asistencia
    ## cambiar el estado del evento a completado
    @event = @corp.events.find(params[:id])
    customer = @event.customer
    respond_to do |format|
      if @event.en_proceso?
        @event.update(status: :completado)
        customer.update(success_events: customer.success_events + 1) if customer

        format.html { redirect_back fallback_location: events_path, notice: "Evento marcado como asistida.", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { redirect_back fallback_location: events_path, alert: "Solo se pueden marcar como asistida los eventos en proceso.", status: :see_other }
        format.json { render json: { error: "Solo se pueden marcar como asistida los eventos en proceso." }, status: :unprocessable_entity }
      end
    end
  end

  def marcar_ausencia
    ## cambiar el estado del evento a ausencia
    @event = @corp.events.find(params[:id])
    customer = @event.customer
    respond_to do |format|
      if  @event.en_proceso?
        @event.update(status: :ausencia)
        customer.update(failed_events: customer.failed_events + 1) if customer

        format.html { redirect_back fallback_location: events_path, notice: "Evento marcado como ausente.", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { redirect_back fallback_location: events_path, alert: "Solo se pueden marcar como ausente los eventos en proceso.", status: :see_other }
        format.json { render json: { error: "Solo se pueden marcar como ausente los eventos en proceso." }, status: :unprocessable_entity }
      end
    end
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
    return redirect_back(fallback_location: user_panel_home_path, alert: "Número de teléfono no proporcionado") if !params[:tel].present? and params[:tel_prefix].present?

    @event = @corp.events.find_by(folio: params[:folio])

    redirect_back(fallback_location: user_panel_home_path, alert: "Objeto no encontrado") if !@event


    full_tel = params[:tel_prefix].strip + params[:tel].strip

    ## Twilio SMS
    response = SmsService.send_sms(to: full_tel, body: "Tu evento programado: #{@event.title}\nFecha y hora: #{@event.hora_inicio.strftime("%d/%m/%Y %I:%M %p")}\nGracias por tu preferencia en #{@corp.name}!")

    puts " --- Enviando SMS a #{full_tel}"
    puts response

    if response[:success]
      redirect_to event_path(@event), notice: "SMS enviado exitosamente."
    else
      redirect_to event_path(@event), alert: "Error al enviar SMS: #{response[:error]}"
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
      :user_id
    ])
  end
end
