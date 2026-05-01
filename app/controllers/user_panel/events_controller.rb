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
              customer: e.customer&.razon&.titleize
            }
          }
        }
      end
    end
  end

  def monthly
    @events = @corp.events

    @q = @events.ransack(params[:q])
  end
  def weekly
    @events = @corp.events

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
      @event.errors.add(:dia, "Duracion del evento es requerida")
      return render :new, status: :unprocessable_entity
    end

    unless params[:event][:inicio_hora].present?
      @event.errors.add(:inicio_hora, "Hora de inicio del evento es requerida")
      return render :new, status: :unprocessable_entity
    end

    unless params[:event][:final_hora].present?
      @event.errors.add(:final_hora, "Hora final del evento es requerida")
      return render :new, status: :unprocessable_entity
    end


    unless params[:event][:user_id].present?
      @event.user_id = current_user.id
    end

    ## parse hours and minutes in format HH:MM
    fecha = params[:event][:dia]
    inicio = params[:event][:inicio_hora]
    fin = params[:event][:final_hora]

    if fecha.present?
      # Convierte la cadena "YYYY-MM-DD 08:30 AM" a DateTime de Rails
      # @event.hora_inicio = Time.zone.parse("#{fecha} #{inicio}") if inicio.present?
      # @event.hora_final = Time.zone.parse("#{fecha} #{fin}") if fin.present?

      tz = ActiveSupport::TimeZone["America/Mexico_City"]
      @event.hora_inicio = tz.parse("#{fecha} #{inicio}") if inicio.present?
      @event.hora_final = tz.parse("#{fecha} #{fin}") if fin.present?

      if @event.hora_inicio.present? && @event.hora_final.present? && @event.hora_final <= @event.hora_inicio
        @event.errors.add(:final_hora, "Hora final debe ser posterior a la hora de inicio")
        return render :new, status: :unprocessable_entity
      end
    end

    ## validar que un evento no se repita en el mismo rango de tiempo en la misma Corp
    # if Event.where(corp_id: @event.corp_id).where("hora_inicio < ? AND hora_final > ?", @event.hora_final, @event.hora_inicio).exists?
    #   @event.errors.add(:hora_inicio, "Ya existe un evento en ese rango de tiempo")
    #   return render :new, status: :unprocessable_entity
    # end

    respond_to do |format|
      if @event.save
        format.html { redirect_to daily_events_path, notice: "Evento creado." }
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
    @event.update(status: :completado)
    respond_to do |format|
      format.html { redirect_back fallback_location: daily_events_path, notice: "Evento marcado como asistida.", status: :see_other }
      format.json { render :show, status: :ok, location: @event }
    end
  end

  def marcar_ausencia
    ## cambiar el estado del evento a cancelado
    @event = @corp.events.find(params[:id])
    @event.update(status: :cancelado)
    respond_to do |format|
      format.html { redirect_back fallback_location: daily_events_path, notice: "Evento marcado como ausente.", status: :see_other }
      format.json { render :show, status: :ok, location: @event }
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to daily_events_path, notice: "Evento actualizado.", status: :see_other }
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
      format.html { redirect_back fallback_location: daily_events_path, notice: "Evento eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_event
    @event = @corp.events.find(params[:id])
  end

  def event_params
    params.expect(event: [
      :title,
      :body,
      :hora_inicio,
      :hora_final,
      :customer_id,
      :user_id
    ])
  end
end
