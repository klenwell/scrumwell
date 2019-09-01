# https://stackoverflow.com/a/18131117/1093087
# https://github.com/mperham/sidekiq/issues/1682#issuecomment-103843390
Sidekiq.configure_server do |config|
  Rails.logger = Sidekiq.logger
  ActiveRecord::Base.logger = Sidekiq.logger
end

# Print backtraces when exceptions occur: https://github.com/mperham/sidekiq/issues/3135
Sidekiq.default_worker_options = { 'backtrace' => true }
