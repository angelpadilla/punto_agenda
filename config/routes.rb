Rails.application.routes.draw do
  devise_for :customers
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "public#home"

  scope "panel" do
    get "", to: "user_panel#home", as: :user_panel_home
    get "landing-purchases", to: "user_panel#landing_purchases", as: :user_panel_landing_purchases
    get "landing-orders", to: "user_panel#landing_orders", as: :user_panel_landing_orders

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

    resources :orders, controller: "user_panel/orders"
    resources :line_items, controller: "user_panel/line_items" do
      collection do
        post :add_item
        post :remove_item
        post :clear_items
      end
    end
  end
end
