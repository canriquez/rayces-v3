Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise routes for JWT authentication
  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations'
             },
             path: '',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               registration: 'signup'
             }

  # Legacy routes (preserve existing MyHub functionality)
  post 'sign_in', to: 'users#sign_in'
  get 'welcome/index'

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      devise_for :users,
                 controllers: {
                   sessions: 'users/sessions',
                   registrations: 'users/registrations'
                 },
                 path: '',
                 path_names: {
                   sign_in: 'login',
                   sign_out: 'logout',
                   registration: 'signup'
                 }
      
      # Organization management
      resource :organization, only: [:show, :update]
      
      # User management
      resources :users, only: [:index, :show, :create, :update, :destroy]
      
      # Appointment management
      resources :appointments do
        member do
          patch :pre_confirm
          patch :confirm
          patch :execute
          patch :cancel
        end
      end
      
      # Professional profiles
      resources :professionals, only: [:index, :show, :create, :update]
      
      # Student management
      resources :students, only: [:index, :show, :create, :update, :destroy]
      
      # Legacy test endpoint
      get 'test', to: 'test#index'
    end
  end

  # Legacy MyHub routes (preserve existing functionality)
  resources :posts do
    resource :like, only: [:create, :destroy, :show]
  end

end
