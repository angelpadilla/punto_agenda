Rails.application.routes.draw do
  devise_for :customers, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  devise_for :admins, controllers: {
    sessions: "users/sessions"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Telegram bot webhook (public, no auth)
  post "telegram/webhook", to: "telegram_webhook#receive"

  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "KlQnEMoLkkAWfl8j2" => "public#html_elements", as: :html_elements
  get "privacidad" => "public#privacidad", as: :privacidad
  get "terminos" => "public#terminos", as: :terminos
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "public#home"

  # SEO Sitemaps
  get "sitemap.xml", to: "sitemaps#index", as: :sitemap
  scope "sitemaps" do
    get "pages.xml", to: "sitemaps#pages", as: :sitemaps_pages
    get "corps.xml", to: "sitemaps#corps", as: :sitemaps_corps
    get "articles.xml", to: "sitemaps#articles", as: :sitemaps_articles
  end

  scope "public" do
    get ":folio/ticket80", to: "public#ticket80", as: :ticket80
    get ":folio/ticket", to: "public#ticket", as: :ticket
    get ":folio/abono_pdf", to: "public#pdf_abono", as: :pdf_abono
    get ":folio/abono_ticket", to: "public#ticket_abono", as: :ticket_abono
    post ":folio/abono_xml", to: "public#abono_xml", as: :abono_xml
    post ":folio/ticket_xml", to: "public#ticket_xml", as: :ticket_xml
  end

  scope "blog" do
    get "", to: "public#index_blog", as: :index_blog
    get ":slug", to: "public#show_blog", as: :show_blog
  end

  scope "e" do
    get ":sku", to: "public#show_corp", as: :corp_home
    get ":sku/cat", to: "public#show_corp_menu", as: :corp_menu
    get ":sku/cal", to: "public#show_corp_calendar", as: :corp_calendar
    get ":sku/reservar", to: "public#new_booking", as: :corp_new_booking
    post ":sku/reservar", to: "public#book_event", as: :corp_book_event
    get "reservar/success", to: "public#book_payment_success", as: :corp_book_payment_success
    get "reservar/success/:folio", to: "public#book_payment_success_show", as: :book_payment_success_show
    get "reservar/error", to: "public#book_payment_error", as: :corp_book_payment_error
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
      post "change_plan", to: "user_panel/corp#change_plan", as: :change_plan
      post "charge_sms", to: "user_panel/corp#charge_sms", as: :charge_sms
      post "charge_timbres", to: "user_panel/corp#charge_timbres", as: :charge_timbres
      post "update_spei", to: "user_panel/corp#update_spei", as: :update_spei
      post "retiro_fondos", to: "user_panel/corp#retiro_fondos", as: :retiro_fondos
      get "danger_zone", to: "user_panel/corp#danger_zone", as: :danger_zone
      post "destroy_corp", to: "user_panel/corp#destroy_corp", as: :destroy_corp
    end

    resources :bills, controller: "user_panel/bills", only: %i[index show] do
      member do
        # get :bill_pdf, as: :pdf
        post :timbra
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
        post :rechazar
        post :cancelar_recurrence

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
        get :reporte_comisiones
        get ":id/ticket_resumen", to: "user_panel/orders#ticket_resumen", as: :ticket_resumen
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
        post :create_for_purchase, as: :create_for_purchase
      end
    end

    resources :users, controller: "user_panel/users" do
      member do
        get :edit_password
        post :update_password
        # post :activate
      end
    end

    # Telegram integration (per corp)
    get "corp/telegram_link", to: "user_panel/telegram#telegram_link", as: :telegram_link_corp
    get "telegram/callback", to: "user_panel/telegram#callback", as: :telegram_callback
    delete "telegram/unlink", to: "user_panel/telegram#unlink", as: :telegram_unlink

    resources :purchases, controller: "user_panel/purchases", only: %i[index show new create] do
      collection do 
        get ":id/compra_resumen", to: "user_panel/purchases#compra_resumen", as: :compra_resumen
        post :cancel
        get :new_gasto, to: "user_panel/purchases#new_gasto", as: :new_gasto
        post :create_gasto, to: "user_panel/purchases#create_gasto", as: :create_gasto
      end
    end

    resources :purchase_items, controller: "user_panel/purchase_items" do
      collection do
        post :add_item
        post :down_item
        post :remove_item
        post :clear_items
        post :add_gasto_item
        post :remove_gasto_item
      end
    end

    resources :tickets, controller: "user_panel/tickets", only: %i[index show new create], as: :user_tickets do
      member do
        post :marcar_resuelto
      end
      resources :ticket_messages, controller: "user_panel/ticket_messages", only: :create, as: :user_ticket_messages
    end
  end

  scope "admin" do
    get "", to: "admin#home", as: :admin_panel_home
    get "experimental", to: "admin#experimental", as: :admin_panel_experimental
    resources :bills, controller: "admin/bills", only: %i[index show], as: :admin_bills do
      member do
        post :timbra
        post :marcar_depositado_corp
        post :marcar_error_corp
      end
    end
    resources :corps, controller: "admin/corps", only: %i[index show edit update], as: :admin_corps do
      member do
        post :extend_prueba
        post :destroy_corp
      end
    end
    resources :admins, controller: "admin/admins", as: :admin_admins do
      member do
        get :edit_password
        post :update_password
      end
    end
    resources :users, controller: "admin/users"
    resources :events, controller: "admin/events"
    resources :items, controller: "admin/items"
    resources :orders, controller: "admin/orders"
    resources :deposits, controller: "admin/deposits"
    resources :posts, controller: "admin/posts" do
      collection do
        get :calendar
        post :import_soro_rss
      end
    end
    resources :tickets, controller: "admin/tickets", only: %i[index show edit update], as: :admin_tickets do
      resources :ticket_messages, controller: "admin/ticket_messages", only: :create, as: :admin_ticket_messages
    end
    resources :traffic_visits, controller: "admin/traffic_visits", only: :index, as: :admin_traffic_visits
  end
end
