# Preview all emails at http://localhost:3000/rails/mailers/bill_mailer
class BillMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/bill_mailer/retiro_success
  def retiro_success
    BillMailer.with(bill: Bill.last, email: "example@example.com").retiro_success
  end

  # Preview this email at http://localhost:3000/rails/mailers/bill_mailer/retiro_error
  def retiro_error
    BillMailer.with(bill: Bill.last, email: "example@example.com").retiro_error
  end
end
