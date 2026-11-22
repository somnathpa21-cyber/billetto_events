Rails.application.routes.draw do
  root "events#index"

  get "/sign-in", to: "clerk#sign_in"
  get "/sign-up", to: "clerk#sign_up"
  get "/auth-status", to: "clerk#status"

  resources :events, only: [:index] do
    post :like, to: "voting#like"
    post :dislike, to: "voting#dislike"
  end
end