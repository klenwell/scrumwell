Rails.application.routes.draw do

  get '/trello/boards', to: 'trello#boards_index'
  get '/trello/boards/:id', to: 'trello#boards_show', as: 'trello_boards_show'
  get '/trello/orgs', to: 'trello#orgs_index'
  get '/trello/orgs/:id/boards', to: 'trello#orgs_boards_index', as: 'trello_orgs_boards'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#index'
end
