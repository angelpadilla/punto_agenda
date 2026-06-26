class BillMailer < ApplicationMailer
  def retiro_success
    @bill = params[:bill]
    email = params[:email]
    @corp = @bill.corp
    @time = params[:time] || Time.current

    mail to: email, subject: "Solicitud de retiro procesada exitosamente"
  end

  def retiro_error
    @bill = params[:bill]
    email = params[:email]
    @corp = @bill.corp
    @time = params[:time] || Time.current


    mail to: email, subject: "Error al procesar la solicitud de retiro"
  end
end
