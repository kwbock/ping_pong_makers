class SpreadsheetConsumerClientServiceImpl
  require "google/api_client"
  require "google_drive"
  DEFAULT_SCOPE = ["https://www.googleapis.com/auth/drive", "https://spreadsheets.google.com/feeds/"]
  CLASS_OPTIONS = %i[google_client_id google_client_secret spreadsheet_name oauth_redirect_url max_wl min_wl cache_time_in_seconds]
  INSTANCE_OPTIONS = %i[client last_fetch_at]

  class Configuration
    attr_accessor *CLASS_OPTIONS
  end

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  attr_accessor *INSTANCE_OPTIONS

  def initialize(options={})
    @client = Google::APIClient.new
    client.authorization.client_id = self.class.configuration.google_client_id
    client.authorization.client_secret = self.class.configuration.google_client_secret
    client.authorization.scope = DEFAULT_SCOPE
    client.authorization.redirect_uri = self.class.configuration.oauth_redirect_url
  end

  def authorization_uri
    client.authorization.authorization_uri
  end

  def authorized?
    ret = true
    session = GoogleDrive.login_with_oauth(@access_token)
    session.spreadsheets
  rescue Google::APIClient::AuthorizationError
    ret = false
  ensure
    return ret
  end

  def authorize!(code)
    client.authorization.code = code
    client.authorization.fetch_access_token!
    @access_token = client.authorization.access_token
  end

  def authorize_from_access_token!(token)
    client.authorization.access_token = token
    @access_token = token
  end

  def access_token
    @access_token
  end

  def players
    if @players.nil? || is_cache_invalid?
      fetch_players!
    end
    @players
  end

  private

  def is_cache_invalid?
    last_fetch_at.nil? || (Time.now - self.class.configuration.cache_time_in_seconds).cover?(last_fetch_at) == false
  end

  def fetch_players!
    @last_fetch_at = Time.now
    trailing_30_days = (Date.today - 30).to_time .. Time.now
    session = GoogleDrive.login_with_oauth(@access_token)
    ss = session.files.select{|f| f.title == self.class.configuration.spreadsheet_name}.first
    ws = ss.worksheets.first
    data = ws.rows[1..-1].select{|row| trailing_30_days.cover?(Date.strptime(row[0], '%m/%d/%Y').to_time)}
    player_names = data.map{|row| [row[3],row[4]]}.flatten.uniq
    players = player_names.map do |name|
      games = data.select{|row| (row[3] == name || row[4] == name)}
      total = games.count
      wins = data.select{|row| (row[5] == name)}.count
      {
        name: name,
        total: total,
        wins: wins,
        losses: total - wins,
        ratio: wins.fdiv(total - wins).round(2),
        power: 0,
        games: games
      }
    end

    #Power ranking calculation
    players.each do |player|
      player_power_base = player[:ratio]
      player_power_base = self.class.configuration.max_wl if player_power_base > self.class.configuration.max_wl
      player_power_base
      player[:power] = player_power_base + player[:games].map do |row|
        if row[5] == player[:name]
          opponent_name = [row[3],row[4]].reject{|name| name == player[:name]}.first
          opponent_ratio = players.select{|p| p[:name] == opponent_name}.first[:ratio]
          opponent_ratio = self.class.configuration.max_wl if opponent_ratio > self.class.configuration.max_wl
          opponent_ratio = self.class.configuration.min_wl if opponent_ratio < self.class.configuration.min_wl
          (row[1].to_i - row[2].to_i).abs * opponent_ratio
        else
          0
        end
      end.inject(&:+)
      player[:power] = (player[:power] * 100.0 / 110.0 * 10.0).round(0)
      player[:power] = -1 if player[:total] < 3
    end

    #Player average margin
    players.each do |player|
      player[:avg_spread] = player[:games].map do |row|
        if row[5] == player[:name]
          (row[1].to_i - row[2].to_i).abs
        else
          0
        end
      end.compact.inject(&:+).fdiv(player[:total]).round(2)
    end
    @players = players.sort_by{|p| p[:power]}.reverse
  end
end