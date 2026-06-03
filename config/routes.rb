Rails.application.routes.draw do
  devise_for :customers
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  devise_for :admins
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobstatus"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "KlQnEMoLkkAWfl8j2" => "public#html_elements", as: :html_elements
  
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  
  # Defines the root path route ("/")
  root "public#home"

  # SEO Sitemaps
  get "sitemap.xml", to: "sitemaps#index", as: :sitemap
  scope "sitemaps" do
    get "pages.xml", to: "sitemaps#pages", as: :sitemaps_pages
    get "corps.xml", to: "sitemaps#corps", as: :sitemaps_corps
  end

  scope "public" do
    get ":folio/ticket80", to: "public#ticket80", as: :ticket80
    get ":folio/ticket", to: "public#ticket", as: :ticket
    get ":folio/abono_pdf", to: "public#pdf_abono", as: :pdf_abono
    get ":folio/abono_ticket", to: "public#ticket_abono", as: :ticket_abono
    post ":folio/abono_xml", to: "public#abono_xml", as: :abono_xml
    post ":folio/ticket_xml", to: "public#ticket_xml", as: :ticket_xml
  end

  scope "e" do
    get ":sku", to: "public#show_corp", as: :corp_home
    get ":sku/cat", to: "public#show_corp_menu", as: :corp_menu
    get ":sku/cal", to: "public#show_corp_calendar", as: :corp_calendar
    post ":sku/reservar", to: "public#book_event", as: :corp_book_event
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
      get "initial-setup", to: "user_panel/corp#initial_corp_setup", as: :initial_corp_setup
      patch "initial-setup", to: "user_panel/corp#save_initial_corp_setup", as: :save_initial_corp_setup
      match "stripe_new_card", to: "user_panel/corp#stripe_new_card", as: :stripe_new_card, via: [ :get, :post ]
      get "stripe_card_success", to: "user_panel/corp#stripe_card_success", as: :stripe_card_success
      get "stripe_card_error", to: "user_panel/corp#stripe_card_error", as: :stripe_card_error
      post "pay_now", to: "user_panel/corp#pay_now", as: :pay_now
    end

    resources :bills, controller: "user_panel/bills", only: %i[index show] do
      member do
        # get :bill_pdf, as: :pdf
        # post :bill_xml, as: :xml
      end
    end

    ## user_panel/items_controller.rb
    resources :items, controller: "user_panel/items" do
      collection do
        get :search_sat_products
      end
    end
    resources :customers, controller: "user_panel/customers" do 
      collection do 
        post :create_from_event
      end
    end
    resources :providers, controller: "user_panel/providers"
    resources :events, controller: "user_panel/events" do
      collection do
        get :monthly
        get :weekly
        get :slot_agents
        post :marcar_asistencia
        post :marcar_ausencia
        post :confirmar
        post :cancelar

        post :send_email, as: :send_email
        post :send_sms, as: :send_sms
        post :send_whatsapp, as: :send_whatsapp
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
        post :timbra, as: :timbra
        post :cancel
      end
    end
    resources :line_items, controller: "user_panel/line_items" do
      collection do
        post :add_item
        post :down_item
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

    resources :users, controller: "user_panel/users" do
      member do
        get :edit_password
        post :update_password
        # post :activate
      end
    end
  end
end
