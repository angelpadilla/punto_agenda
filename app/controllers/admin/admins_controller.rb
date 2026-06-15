class Admin::AdminsController < AdminController
  before_action :set_admin, only: %i[show edit edit_password update_password update destroy]

  def index
    admins = Admin.default

    @q = admins.ransack(params[:q])
    @pagy, @admins = pagy(@q.result(distinct: true), limit: 20)
  end

  def show
  end

  def new
    @admin = Admin.new
  end

  def edit
  end
  
  def edit_password
    redirect_to admin_admins_path, alert: "No tienes permisos para editar este usuario." unless @admin.admin?
  end

  def update_password
    redirect_to admin_admins_path, alert: "No tienes permisos para editar este usuario." unless @admin.admin?

    if @admin.update(password_params)
      redirect_to admin_admin_path(@admin), notice: "Contraseña actualizada exitosamente."
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def create
    @admin = Admin.new(admin_params)

    if @admin.save
      redirect_to admin_admin_path(@admin), notice: "Usuario creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @admin.update(admin_params)
      redirect_to admin_admin_path(@admin), notice: "Usuario actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin.destroy
    redirect_to admin_admins_path, notice: "Usuario eliminado exitosamente."
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def password_params
    params.require(:admin).permit(:password, :password_confirmation)
  end

  def admin_params
    params.require(:admin).permit(:full_name, :email, :password, :password_confirmation, :rol, :active)
  end
end