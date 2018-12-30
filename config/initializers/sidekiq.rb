# https://stackoverflow.com/a/18131117/1093087
Sidekiq.configure_server do |config|
  Rails.logger = Sidekiq::Logging.logger
end
