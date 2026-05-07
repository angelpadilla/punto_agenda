Rails.application.routes.draw do
  devise_for :customers
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "KlQnEMoLkkAWfl8j2" => "public#html_elements", as: :html_elements

  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "public#home"

  scope "public" do
    get ":folio/ticket80", to: "public#ticket80", as: :ticket80
    get ":folio/ticket", to: "public#ticket", as: :ticket
    get ":folio/abono_pdf", to: "public#pdf_abono", as: :pdf_abono
    get ":folio/abono_ticket", to: "public#ticket_abono", as: :ticket_abono
    get ":folio/abono_xml", to: "public#abono_xml", as: :abono_xml
  end

  scope "panel" do
    get "", to: "user_panel#home", as: :user_panel_home
    get "landing-purchases", to: "user_panel#landing_purchases", as: :user_panel_landing_purchases
    get "landing-orders", to: "user_panel#landing_orders", as: :user_panel_landing_orders

    scope "corp" do
      get "", to: "user_panel/corp#landing", as: :user_corp_landing
      get "show", to: "user_panel/corp#show", as: :user_corp
      get "edit", to: "user_panel/corp#edit", as: :edit_user_corp
      patch "edit", to: "user_panel/corp#update", as: :update_user_corp
    end

    ## user_panel/items_controller.rb
    resources :items, controller: "user_panel/items"
    resources :customers, controller: "user_panel/customers"
    resources :providers, controller: "user_panel/providers"
    resources :events, controller: "user_panel/events" do
      collection do
        get :monthly
        get :weekly
        get :daily
        post :marcar_asistencia
        post :marcar_ausencia
      end
    end
    resources :brands, controller: "user_panel/brands" do
      collection do
        post :create_from_item
      end
    end

    resources :orders, controller: "user_panel/orders" do
      collection do
        post ":folio/send_sms", to: "user_panel/orders#send_sms", as: :send_sms
        post :send_email, as: :send_email
        post :cancel
      end
    end
    resources :line_items, controller: "user_panel/line_items" do
      collection do
        post :add_item
        post :remove_item
        post :clear_items
      end
    end

    resources :deposits, controller: "user_panel/deposits", except: [ :new, :edit, :update ] do 
      collection do
        post :modificar_forma_pago, as: :modificar_forma_pago
        post :send_abono_email, as: :send_abono_email
      end
    end
  end
end
