class PagesController < ApplicationController
  before_filter :redirect_to_auth
  def home
    client.authorize!(code)
    @players = client.players
  end

  private

  def client
    @client ||= SpreadsheetConsumerClientServiceImpl.new
  end

  def redirect_to_auth
    if params[:code].nil?
      redirect_to client.authorization_uri.to_s
    end
  end

  def code
    @code ||= params[:code].to_s
  end
end
