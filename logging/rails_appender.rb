module Log4JSupport

  java_import 'org.apache.logging.log4j.Level' do |pkg, cls|
    'JLevel'
  end

  class RailsFilter <  org.apache.logging.log4j.core.filter.AbstractFilter
    #not doing diddly squat for now....
  end

  class RailsLayout < org.apache.logging.log4j.core.layout.AbstractLayout
    def initialize
      super(nil,nil)
    end
  end

  class RailsAppender < org.apache.logging.log4j.core.appender.AbstractAppender

    def initialize
      super('RailsAppender',RailsFilter.new, RailsLayout.new)
      set_level
    end

    def set_level
      logger = org.apache.logging.log4j.LogManager.getRootLogger
#levels :debug, :info, :warn, :error, :fatal, :unknown, :always
      case $log.level
        when PRISME_LOG_LEVELS[:debug]
          level = org.apache.logging.log4j.Level::TRACE
          logger.setLevel(level)
        when PRISME_LOG_LEVELS[:info]
          level = org.apache.logging.log4j.Level::INFO
          logger.setLevel(level)
        when PRISME_LOG_LEVELS[:warn]
          level = org.apache.logging.log4j.Level::WARN
          logger.setLevel(level)
        when PRISME_LOG_LEVELS[:error]
          level = org.apache.logging.log4j.Level::ERROR
          logger.setLevel(level)
        when PRISME_LOG_LEVELS[:fatal]
          level = org.apache.logging.log4j.Level::FATAL
          logger.setLevel(level)
      end
    end

    def append(log_event)
      level = log_event.getLevel
      logger_name = log_event.getLoggerName
      message = log_event.getMessage.getFormattedMessage
      source = log_event.getSource
      case level
        when JLevel::TRACE, JLevel::DEBUG
          $log.debug("J::#{logger_name} | #{message} | #{source}")
        when JLevel::INFO
          $log.info("J::#{logger_name} | #{message} | #{source}")
        when JLevel::WARN
          $log.warn("J::#{logger_name} | #{message} | #{source}")
        when JLevel::ERROR
          $log.error("J::#{logger_name} | #{message} | #{source}")
        when JLevel::FATAL
          $log.fatal("J::#{logger_name} | #{message} | #{source}")
        when JLevel::ALL
          $log.always("J::#{logger_name} | #{message} | #{source}")
        else
          $log.unknown("J::#{logger_name} | #{message} | #{source}")
      end
    end
  end
end

#root logger is a org.apache.logging.log4j.core.Logger
org.apache.logging.log4j.LogManager.getRootLogger.addAppender(Log4JSupport::RailsAppender.new)
