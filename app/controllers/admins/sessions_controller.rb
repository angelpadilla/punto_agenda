# frozen_string_literal: true

class Admins::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  prepend_before_action :verify_turnstile, only: [ :create ]

  # # 1. Burst Control: Max 3 requests every 2 seconds
  # rate_limit to: 3, within: 2.seconds, name: "burst_control",
  #   by: -> { request.ip },
  #   with: -> { redirect_to new_admin_session_path, alert: "Demasiados intentos de inicio de sesión. Por favor, inténtalo de nuevo en unos segundos." }

  # # 2. Daily protection: Max 1000 requests every 1 hour
  # rate_limit to: 1000, within: 1.hour, name: "daily_protection",
  #   by: -> { request.ip },
  #   with: -> { redirect_to new_admin_session_path, alert: "Demasiados intentos de inicio de sesión. Por favor, inténtalo de nuevo más tarde." }

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def verify_turnstile
    puts "Verificando turnstile..."
    puts "--- ip request: #{request.remote_ip} ---"
    ## verificamos captcha
    token = params["cf-turnstile-response"]
    secret_key =  Rails.application.credentials.dig(Rails.env.to_sym, :turnstile, :secret_key)
    response = HTTP.post("https://challenges.cloudflare.com/turnstile/v0/siteverify", form: {
      secret: secret_key,
      response: token,
      remoteip: request.remote_ip
    })

    puts "Turnstile response: #{response}"
    if response.status.success?
      body = JSON.parse(response.to_s)
      unless body["success"]
        ## captcha no valido
        flash[:alert] = "Error al verificar el captcha, error: #{body['error-codes'].join(', ')}"
        self.resource = resource_class.new(sign_in_params)
        clean_up_passwords(resource)

        # USAR RENDER CON STATUS 422 (Importante para Turbo)
        render :new, status: :unprocessable_entity
      end
    else
      ## error en la peticion
      flash[:alert] = "Error en peticion, status: #{response.status}"
      self.resource = resource_class.new(sign_in_params)
      clean_up_passwords(resource)

      # USAR RENDER CON STATUS 422 (Importante para Turbo)
      render :new, status: :unprocessable_entity
    end
  end
end
