Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  root "quiz#landing"
  post "/start", to: "quiz#start", as: :start_quiz
  get  "/quiz",  to: "quiz#quiz",  as: :quiz
  post "/quiz/submit", to: "quiz#submit", as: :submit_quiz
  get  "/results/:id", to: "quiz#results", as: :results

  namespace :admin do
    root "dashboard#index", as: :dashboard
    get  "/dashboard", to: "dashboard#index", as: :dashboard_page
    get  "/results", to: "results#index", as: :results
    get  "/results.xlsx", to: "results#export", as: :results_export
    get  "/import", to: "import#index", as: :import
    post "/import", to: "import#create"
  end
end
