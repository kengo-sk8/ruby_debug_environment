Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check
  get "cat_fact", to: "application#cat_fact"
end
