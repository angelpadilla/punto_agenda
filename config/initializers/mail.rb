ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.default charset: "utf-8"
ActionMailer::Base.smtp_settings = {
  authentication: :plain,
  address: "smtp-pulse.com",
  port: 587,
  domain: "ghoster.mx",
  user_name: "noodusmx@gmail.com",
  password: "A6DRgDefC554"
}
