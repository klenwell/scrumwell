# For settings, see: https://github.com/trusche/httplog#configuration
HttpLog.configure do |config|
  config.logger = Rails.logger
  config.compact_log = true
end
