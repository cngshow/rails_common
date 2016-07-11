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
      @exception_lambda = ->(throwable_array) do
        message = ""
        throwable_array.each do |throwable|
          message << "\n"
          message << "#{throwable.getMessage}\n"
          message << throwable.backtrace.join("\n\t")
        end
        message
      end
    end

    def append(log_event)

      level = log_event.getLevel
      logger_name = log_event.getLoggerName
      message = log_event.getMessage.getFormattedMessage
      source = log_event.getSource
      t_a = []
      throwable = get_throwables(log_event.getThrownProxy.getThrowable, t_a)  unless log_event.getThrownProxy.nil?
      case level
        when JLevel::TRACE, JLevel::DEBUG
          $log.debug("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.debug(@exception_lambda.call(throwable))
          end
        when JLevel::INFO
          $log.info("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.info(@exception_lambda.call(throwable))
          end
        when JLevel::WARN
          $log.warn("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.warn(@exception_lambda.call(throwable))
          end
        when JLevel::ERROR
          $log.error("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.error(@exception_lambda.call(throwable))
          end
        when JLevel::FATAL
          $log.fatal("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.fatal(@exception_lambda.call(throwable))
          end
        when JLevel::ALL
          $log.always("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.always(@exception_lambda.call(throwable))
          end
        else
          $log.unknown("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.unknown(@exception_lambda.call(throwable))
          end
      end
    end

    private

    def get_throwables(root_throwable, array)
      return array if root_throwable.nil?
      array << root_throwable
      next_throw = root_throwable.getCause
      return get_throwables(next_throw, array)
    end

  end
end
java.lang.System.getProperties['log4j.configurationFile'] = "file:/#{Rails.root}/lib/rails_common/logging/log4j2.xml"
#root logger is an org.apache.logging.log4j.core.Logger
org.apache.logging.log4j.LogManager.getRootLogger.addAppender(Log4JSupport::RailsAppender.new)
