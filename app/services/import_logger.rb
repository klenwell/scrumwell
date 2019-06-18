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
    logger.formatter = self.formatter()
    logger
  end

  def self.init_error_logger
    logger = Logger.new(ErrorLogFile)
    logger.formatter = self.formatter()
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
