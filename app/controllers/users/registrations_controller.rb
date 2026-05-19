# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    puts "Verificando turnstile..."
    puts "--- ip request: #{request.remote_ip} ---"
    token = params["cf-turnstile-response"]
    secret_key =  Rails.application.credentials.dig(Rails.env.to_sym, :turnstile, :secret_key)
    response = HTTP.post("https://challenges.cloudflare.com/turnstile/v0/siteverify", form: {
      secret: secret_key,
      response: token,
      remoteip: request.remote_ip
    })

    if params[:tipo_negocio].present? and [ "barberia", "salon_belleza", "servicios" ].include?(params[:tipo_negocio])
      calendar = true
    else
      calendar = false
    end

    corp = Corp.new(
      tipo_negocio: params[:tipo_negocio] || "otro",
      calendar: calendar,
      regimen: "616",
      phone: params[:user][:tel].to_s,
      tel_prefix: params[:user][:tel_prefix].to_s,
      name: "Compañía de #{params[:user][:full_name]}"
    )

    if response.status.success?
      body = JSON.parse(response.to_s)
      puts body
      build_resource(sign_up_params)
      resource.tipo = "propietario"
      resource.tel_prefix = params[:user][:tel_prefix] || "+52"

      if resource.save
        if corp.save # Guardar el Corp solo si el usuario se guarda correctamente
          resource.update(corp_id: corp.id)
          yield resource if block_given?
          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
            respond_with resource, location: after_sign_up_path_for(resource)
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
            respond_with resource, location: after_inactive_sign_up_path_for(resource)
          end
        else
          resource.destroy # Eliminar el usuario si el Corp no se guarda
          flash[:alert] = "Error al crear el usuario: #{corp.errors.full_messages.join(', ')}"
          redirect_to new_user_registration_path
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      flash[:alert] = "Error en verificación, status: #{response.status}"
      redirect_to new_user_registration_path
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name, :tel, :tel_prefix ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
