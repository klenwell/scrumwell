# Based on:
#   https://stackoverflow.com/a/12380618/1093087
#   https://stackoverflow.com/a/34202875/1093087
#
# Usage: ImportLogger.error('hi')
class ImportLogger

  LogFile = Rails.root.join('log', 'import.log')
  ErrorLogFile = Rails.root.join('log', 'import-error.log')

  def self.formatter
    Proc.new{|severity, time, progname, msg|
      formatted_severity = sprintf("%-5s",severity.to_s)
      formatted_time = time.strftime("%Y-%m-%d %H:%M:%S")
      "[#{formatted_severity} #{formatted_time} #{$$}] #{msg.to_s.strip}\n"
    }
  end

  def self.init_logger
    logger = Logger.new(LogFile)
    stdout_logger = Logger.new(STDOUT)
    logger.formatter = self.formatter()

    # https://stackoverflow.com/a/26704547/1093087
    logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))

    logger
  end

  def self.init_error_logger
    logger = Logger.new(ErrorLogFile)
    stderr_logger = Logger.new(STDERR)
    logger.formatter = self.formatter()

    # https://stackoverflow.com/a/26704547/1093087
    logger.extend(ActiveSupport::Logger.broadcast(stderr_logger))

    logger
  end

  def self.debug(msg)
    @@logger ||= self.init_logger
    @@logger.debug(msg)
  end

  def self.info(msg)
    @@logger ||= self.init_logger
    @@logger.info(msg)
  end

  def self.error(msg)
    @@error_logger ||= self.init_error_logger
    @@error_logger.error(msg)
  end
end
