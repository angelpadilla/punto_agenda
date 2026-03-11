Rails.application.routes.draw do
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

    ## user_panel/items_controller.rb
    resources :items, controller: "user_panel/items"
    resources :brands, controller: "user_panel/brands" do 
      collection do
        post :create_from_item
      end
    end
  end
end
