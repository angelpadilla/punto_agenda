class CobranzaMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.cobranza_mailer.success_payment.subject
  #
  def success_payment
    @corp = params[:corp]
    @bill = params[:bill]
    email = params[:email]
    pdf = BillPdf.new(@bill)
    attachments["#{@bill.folio}.pdf"] = pdf.render

    mail(to: email, subject: "MiiNegocio pago suscripción exitoso #{@bill.folio}")
  end

  def failed_payment
    @corp = params[:corp]
    @bill = params[:bill]
    email = params[:email]

    mail(to: email, subject: "MiiNegocio pago suscripción fallido #{@bill.folio}")
  end

  def suspendido
    @corp = params[:corp]
    @bill = params[:bill]
    email = params[:email]

    mail(to: email, subject: "MiiNegocio cuenta suspendida por pagos fallidos #{@bill.folio}")
  end
end
