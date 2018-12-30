# Wraps trello-ruby gem.
class LogService
  def self.log(message, level=:debug)
    Rails.logger.send(level, message)
  end

  def self.rake(message, level=:debug)
    log(message, level)
    to_stdout(message)
  end

  def self.dev(message, level=:debug)
    return unless Rails.env.development?
    rake(message, level)
  end

  #
  # Stdout
  #
  def self.to_stdout(message)
    puts message # rubocop: disable Rails/Output
  rescue StandardError
    # Sidekiq doesn't like puts statement
    log('LogService.to_stdout failed!')
  end

  def self.pretty(message)
    pp message # rubocop: disable Rails/Output
  rescue StandardError
    # Forget about it.
  end
end
