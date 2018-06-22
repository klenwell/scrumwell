Rails.application.routes.draw do

  get '/trello/boards', to: 'trello#boards_index'
  get '/trello/orgs', to: 'trello#orgs_index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#index'
end
