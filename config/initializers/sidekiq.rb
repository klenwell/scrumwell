# https://stackoverflow.com/a/18131117/1093087
Sidekiq.configure_server do |config|
  Rails.logger = Sidekiq::Logging.logger
end

# Print backtraces when exceptions occur: https://github.com/mperham/sidekiq/issues/3135
Sidekiq.default_worker_options = { 'backtrace' => true }
