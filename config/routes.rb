Rails.application.routes.draw do

  # Scrum Routes
  # http://guides.rubyonrails.org/routing.html#controller-namespaces-and-routing
  namespace :scrum do
    # Nested Resources: https://stackoverflow.com/a/10661690/1093087
    resources :boards, shallow: true do
      member do
        # Show view tabs.
        get 'sprints', to: 'boards#show'
        get 'chart', to: 'boards#show'
        get 'contributors', to: 'boards#show'
        get 'events', to: 'boards#show'
        get 'imports', to: 'boards#show'
      end

      resources :queues, shallow: true do
        resources :stories, except: [:index]

        member do
          # Show view tabs.
          get 'stories', to: 'queues#show'
          get 'contributors', to: 'queues#show'
          get 'events', to: 'queues#show'
        end
      end

      resources :events
    end

    resources :contributors, only: [:index, :show] do
      member do
        # Show view tabs.
        get 'sprints', to: 'contributors#show'
        get 'stories', to: 'contributors#show'
      end
    end

    post 'board/import', to: 'boards#import'
  end

  # Trello Routes
  namespace :trello do
    resources :boards, only: [:index, :show] do
      collection do
        get 'all', to: 'boards#index'
        get 'scrum', to: 'boards#scrum'
      end
    end

    post 'board/import', to: 'boards#import'
  end
  get '/trello/imports', to: 'trello/imports#index'
  get '/trello/imports/:id', to: 'trello/imports#show', as: 'trello_import'
  patch '/trello/imports/abort/:id', to: 'trello/imports#abort', as: 'trello_import_abort'
  get '/trello/orgs', to: 'trello#orgs_index'
  get '/trello/orgs/:id/boards', to: 'trello#orgs_boards_index', as: 'trello_orgs_boards'

  # Charts Routes
  get '/charts/scrum_board/:id', to: 'charts#scrum_board', as: 'scrum_board_charts'

  # Authentication
  get '/authenticate', to: 'sessions#new', as: :auth_confirm
  get '/auth/:provider/callback', to: 'sessions#create', as: :auth_callback
  get '/sign_out', to: 'sessions#destroy', as: :sign_out
  get '/auth/failure', to: 'sessions#failure'

  # Sidekiq Monitor
  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#index'
end
