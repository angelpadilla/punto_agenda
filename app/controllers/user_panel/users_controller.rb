class UserPanel::UsersController < UserPanelController
  include CorpCan
  before_action :set_user, only: %i[show edit update destroy edit_password update_password]
  before_action :stop_corp_basico, only: %i[index new create destroy]

  def index
    # stop_corp_basico
    users = @corp.users.default

    @q = users.ransack(params[:q])
    @pagy, @users = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
    # validations
    if current_user.colaborador? and @user.id != current_user.id
      redirect_to user_panel_home_path, alert: "No tienes permisos para ver este usuario."
    end
  end

  def new
    @user = @corp.users.new
  end

  def edit
    stop_corp_basico if @user.id != current_user.id
  end

  def edit_password
    stop_corp_basico if @user.id != current_user.id
  end

  def update_password
    stop_corp_basico if @user.id != current_user.id
    if @user.update(password_params)
      redirect_to @user, notice: "Contraseña actualizada exitosamente."
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def create
    @user = @corp.users.new(user_params)

    if @user.save
      redirect_to @user, notice: "Usuario creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    stop_corp_basico if @user.id != current_user.id
    if @user.update(user_params)
      redirect_to @user, notice: "Usuario actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return redirect_to users_path, alert: "No puedes eliminar este usuario." if current_user.prop?
    return redirect_to users_path, alert: "No puedes eliminar tu propio usuario." if @user == current_user
    return redirect_to users_path, alert: "No tienes permiso para realizar esta acción." unless current_user.prop?
    @user.destroy
    redirect_to users_path, notice: "Usuario eliminado exitosamente."
  end


  private

  def set_user
    @user = @corp.users.find(params[:id])
  end

  def user_params
    params.expect(user: [ :full_name, :tel, :tel_prefix, :tipo, :active, :email, :password, :password_confirmation, :work_start_time, :work_end_time ])
  end

  def password_params
    params.expect(user: [ :password, :password_confirmation ])
  end
end
