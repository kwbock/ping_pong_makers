SpreadsheetConsumerClientServiceImpl.configure do |config|
  config.google_client_id = ENV.fetch("GOOGLE_CLIENT_ID")
  config.google_client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")
  config.spreadsheet_name = ENV.fetch("SPREADSHEET_NAME")
  config.oauth_redirect_url = ENV.fetch("OAUTH_REDIRECT_URL")
  config.max_wl = ENV.fetch("MAX_WL").to_i # 5
  config.min_wl = 1.fdiv(config.max_wl)
  config.cache_time_in_seconds = 60
end