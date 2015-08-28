# == Route Map
#
#    Prefix Verb URI Pattern          Controller#Action
#      root GET  /                    pages#home
#

Rails.application.routes.draw do
  root 'pages#home'
end
