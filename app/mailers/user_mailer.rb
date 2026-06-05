class UserMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @corp = @user.corp
    mail(to: @user.email, subject: "Bienvenido a MiiNegocio.com")
  end
end
