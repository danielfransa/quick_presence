Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  get "/account-deleted", to: "accounts#deleted", as: :account_deleted

  authenticated :user do
    root "attendance_lists#index", as: :authenticated_root
  end

  unauthenticated do
    root "home#index"
  end

  resources :attendance_lists do
    member do
      get :responses
      get :export
      get :qr_code_pdf
      patch :close
    end
  end

  get "/a/:public_token", to: "public_attendance#show", as: :public_attendance
  post "/a/:public_token", to: "public_attendance#create"

  get "/favicon.ico", to: redirect("/icon.png")

  get "up" => "rails/health#show", as: :rails_health_check
end
