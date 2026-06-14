class Admin::AdminsController < AdminController
  before_action :set_admin, only: %i[show edit update destroy]

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

  def create
    @admin = Admin.new(admin_params)

    if @admin.save
      redirect_to admin_admin_path(@admin), notice: "Administrador creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @admin.update(admin_params)
      redirect_to admin_admin_path(@admin), notice: "Administrador actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin.destroy
    redirect_to admin_admins_path, notice: "Administrador eliminado exitosamente."
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def admin_params
    params.require(:admin).permit(:full_name, :email, :password, :password_confirmation, :rol, :active)
  end
end