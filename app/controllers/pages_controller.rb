class PagesController < ApplicationController
  before_filter :redirect_to_auth, only: [:home]

  def home
    @players = client.players
  end

  def redirect_from_auth
    access_token = client.authorize!(code)
    session[:access_token] = access_token
    redirect_to root_url
  end
  private

  def client
    @client ||= SpreadsheetConsumerClientServiceImpl.new
    @client.authorize_from_access_token!(session[:access_token])
    @client
  end

  def redirect_to_auth
    if session[:access_token].nil? || client.authorized? == false
      redirect_to client.authorization_uri.to_s
    end
  end

  def code
    @code ||= params[:code].to_s
  end
end
