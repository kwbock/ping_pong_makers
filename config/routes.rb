# == Route Map
#
#    Prefix Verb URI Pattern          Controller#Action
#      root GET  /                    pages#home
#

Rails.application.routes.draw do
  root 'pages#home'
  get 'oauth' => 'pages#redirect_from_auth'
end
