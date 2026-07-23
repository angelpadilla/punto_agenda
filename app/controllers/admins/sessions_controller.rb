# frozen_string_literal: true

class Admins::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  prepend_before_action :verify_turnstile, only: [ :create ]

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
