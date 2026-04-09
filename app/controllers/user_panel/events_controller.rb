class UserPanel::EventsController < UserPanelController
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    events = @corp.events.default

    @q = events.ransack(params[:q])
    @pagy, @events = pagy(@q.result(distinct: true), limit: 10)
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
    @event = Event.new
  end

  def edit
  end

  def create
    @event = @corp.events.new(event_params)

    ## validaciones extras
    unless params[:event][:horas].present?
      @event.errors.add(:horas, "Duracion de la cita es requerida")
      return render :new, status: :unprocessable_entity
    end

    unless params[:event][:user_id].present?
      @event.user_id = current_user.id
    end

    ## parse hours and minutes in format HH:MM
    horas_minutos = params[:event][:horas].split(":")
    puts "-- horas: #{horas_minutos[0].to_i}"
    puts "-- minutos: #{horas_minutos[1].to_i}"

    @event.hora_final = @event.hora_inicio + horas_minutos[0].to_i.hours + horas_minutos[1].to_i.minutes
    puts "fecha_final: #{@event.hora_final}"

    ## validar que un evento no se repita en el mismo rango de tiempo en la misma Corp
    # if Event.where(corp_id: @event.corp_id).where("hora_inicio < ? AND hora_final > ?", @event.hora_final, @event.hora_inicio).exists?
    #   @event.errors.add(:hora_inicio, "Ya existe un evento en ese rango de tiempo")
    #   return render :new, status: :unprocessable_entity
    # end

    respond_to do |format|
      if @event.save
        format.html { redirect_to daily_events_path, notice: "Cita creado." }
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
      format.html { redirect_back fallback_location: daily_events_path, notice: "Cita marcada como asistida.", status: :see_other }
      format.json { render :show, status: :ok, location: @event }
    end
  end

  def marcar_ausencia
    ## cambiar el estado del evento a cancelado
    @event = @corp.events.find(params[:id])
    @event.update(status: :cancelado)
    respond_to do |format|
      format.html { redirect_back fallback_location: daily_events_path, notice: "Cita marcada como ausente.", status: :see_other }
      format.json { render :show, status: :ok, location: @event }
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to daily_events_path, notice: "Cita actualizado.", status: :see_other }
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
      format.html { redirect_back fallback_location: daily_events_path, notice: "Cita eliminado.", status: :see_other }
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
