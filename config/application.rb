require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scrumwell
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Configure Logger
    # https://stackify.com/rails-logger-and-rails-logging-best-practices/
    config.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
    config.logger.level = Logger::DEBUG
    config.logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    config.logger.formatter = proc do | severity, datetime, progname, message |
      "[#{datetime}] #{severity}: #{progname} #{message}\n"
    end
  end
end
