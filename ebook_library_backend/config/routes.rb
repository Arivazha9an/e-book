Rails.application.routes.draw do
  # Simple health check the Flutter app can ping on startup to confirm
  # connectivity to the backend.
  get "/api/v1/health", to: "api/v1/health#show"

  namespace :api do
    namespace :v1 do
      resources :ebooks, only: [:index, :create, :show, :destroy] do
        collection do
          get :search
        end

        member do
          get :download
          match "progress", to: "ebooks#progress", via: :get, as: :progress
          match "progress", to: "ebooks#update_progress", via: :patch, as: :update_progress
        end
      end
    end
  end
end
