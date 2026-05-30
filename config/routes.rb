Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Preview emails in development
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "quiz#landing"
  post "/start", to: "quiz#start", as: :start_quiz
  get  "/quiz",  to: "quiz#quiz",  as: :quiz
  post "/quiz/submit", to: "quiz#submit", as: :submit_quiz
  get  "/results/:id", to: "quiz#results", as: :results

  # Admin routes
  get  "/admin/import", to: "admin#import", as: :admin_import
  post "/admin/import", to: "admin#import_questions"
end
