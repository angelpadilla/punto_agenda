# Preview all emails at http://localhost:3000/rails/mailers/cobranza_mailer
class CobranzaMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/cobranza_mailer/success_payment
  def success_payment
    CobranzaMailer.with(corp: Corp.first, bill: Bill.first).success_payment
  end

  # Preview this email at http://localhost:3000/rails/mailers/cobranza_mailer/failed_payment
  def failed_payment
    CobranzaMailer.with(corp: Corp.first, bill: Bill.first).failed_payment
  end
end
