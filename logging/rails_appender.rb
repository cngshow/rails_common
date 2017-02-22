module Log4JSupport

  java_import 'org.apache.logging.log4j.Level' do |pkg, cls|
    'JLevel'
  end

  #class currently unused
  class RailsContextSelector
    #class currently unused
    include org.apache.logging.log4j.core.selector.ContextSelector

    def getContext(fqcn, loader, currentContext)
      getOnlyContext
    end

    def getContext(fqcn, loader, currentContext, configLocation)
      getOnlyContext
    end

    def getLoggerContexts
      [getOnlyContext]
    end

    def removeContext(context)

    end

    private

    def getOnlyContext
      @@context ||= org.apache.logging.log4j.core.LoggerContext.new('RailsContext')
      @@context
    end
  end

  class RailsFilter < org.apache.logging.log4j.core.filter.AbstractFilter
    #not doing diddly squat for now....
  end

  class RailsLayout < org.apache.logging.log4j.core.layout.AbstractLayout
    def initialize
      super(nil, nil)
    end
  end

  class RailsAppender < org.apache.logging.log4j.core.appender.AbstractAppender

    def initialize
      super('RailsAppender', RailsFilter.new, RailsLayout.new)
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
      throwable = get_throwables(log_event.getThrownProxy.getThrowable, t_a) unless log_event.getThrownProxy.nil?
      case level
        when JLevel::TRACE, JLevel::DEBUG
          $log.debug("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.debug(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :debug, message, source, throwable)
        when JLevel::INFO
          $log.info("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.info(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :info, message, source, throwable)
        when JLevel::WARN
          $log.warn("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.warn(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :warn, message, source, throwable)
        when JLevel::ERROR
          $log.error("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.error(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :error, message, source, throwable)
        when JLevel::FATAL
          $log.fatal("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.fatal(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :fatal, message, source, throwable)
        when JLevel::ALL
          $log.always("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.always(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :always, message, source, throwable)
        else
          $log.unknown("J::#{logger_name} | #{message} | #{source}")
          if throwable
            $log.unknown(@exception_lambda.call(throwable))
          end
          jar_based_logging(log_event, :unknown, message, source, throwable)
      end
    end

    private

    def get_throwables(root_throwable, array)
      return array if root_throwable.nil?
      array << root_throwable
      next_throw = root_throwable.getCause
      return get_throwables(next_throw, array)
    end

    def jar_appender(jar)
      ::Logging.appenders.rolling_file(
          'file',
          layout: ::Logging.layouts.pattern(
              pattern: $PROPS['LOG.pattern'],
          #    color_scheme: 'pretty',
          #    backtrace: true
          ),
          roll_by: $PROPS['LOG.roll_by'],
          keep: $PROPS['LOG.keep'].to_i,
          age: $PROPS['LOG.age'],
          filename: JAR_LOG_HOME + jar.to_s + '.log',
          truncate: true
      )
    end

    #Jar is file:/C:/work/va-ctt/rails/rails_prisme/lib/jars/hl7-messaging.jar
    #Jar is file:/C:/work/va-ctt/rails/rails_prisme/lib/jars/ochre-api.jar
    def jar_based_logging(log_event, level, message, source, throwable)
      jar = nil
      @@logger_map ||= {}
      begin
        class_string = log_event.getSource.getClassName
        cl = JLookupService.java_class.to_java.getClassLoader
        clazz = cl.loadClass class_string
        jar = clazz.getProtectionDomain().getCodeSource().getLocation.to_s.split('/').last
      rescue => ex
        $log.error("Could not inspect a log event #{log_event}")
        $log.error(ex.backtrace.join("\n"))
        return nil
      end
      if (@@logger_map[jar].nil?)
        @@logger_map[jar] = ::Logging::Logger[jar.to_s]
        @@logger_map[jar].caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')
        @@logger_map[jar].add_appenders 'stdout' if ($PROPS['LOG.append_stdout'].eql?('true')) # || $rake (ad that in to see log in vadev jenkins build)
        @@logger_map[jar].add_appenders jar_appender(jar)
        @@logger_map[jar].level = $PROPS['LOG.level'].downcase.to_sym
      end
      #@@logger_map[jar]
      #puts "Jar is #{jar.to_s.split('/').last}, lm is #{@@logger_map[jar]}" #if jar.to_s =~ /hl7/i
      @@logger_map[jar].send(level, "#{message} | #{source}")
      if throwable
        #ts = @exception_lambda.call(throwable)
        #puts "throwable is #{throwable}, ts is #{ts}"
        @@logger_map[jar].send(level, @exception_lambda.call(throwable))
      end
    end
  end
end
#java.lang.System.getProperties['log4j.configurationFile'] = "file:/#{Rails.root}/lib/rails_common/logging/log4j2.xml"
#root logger is an org.apache.logging.log4j.core.Logger
#fact = org.apache.logging.log4j.core.impl.Log4jContextFactory.new(Log4JSupport::RailsContextSelector.new)
#org.apache.logging.log4j.LogManager.setFactory(fact)
org.apache.logging.log4j.LogManager.getRootLogger.addAppender(Log4JSupport::RailsAppender.new)

# java_import 'gov.vha.isaac.ochre.pombuilder.upload.SrcUploadCreator' do |p,c|
#   'JS'
# end


#this line is useful for debugging in eclipse to see if your appender is registered
# ((org.apache.logging.log4j.core.Logger)LogManager.getRootLogger()).getAppenders()
#JS.java_class.to_java.getClassLoader

# cl = JS.java_class.to_java.getClassLoader
# lmclass = cl.loadClass('org.apache.logging.log4j.LogManager')
# m = lmclass.getDeclaredMethod('getRootLogger')
# root_logger = m.invoke(lmclass)
# root_logger.addAppender(Log4JSupport::RailsAppender.new)

# org.apache.logging.log4j.core.LoggerContext@63d93e91

# main DEBUG LoggerContext[name=14dad5dc, org.apache.logging.log4j.core.LoggerContext@f5b079f] started OK.

#debug 1
# org.apache.logging.log4j.core.LoggerContext@127205ac
# 2016-07-21 11:28:01,823 main DEBUG LoggerContext[name=5a14e60d, org.apache.logging.log4j.core.LoggerContext@127205ac] started OK.

# context 2:
# org.apache.logging.log4j.core.LoggerContext@5c2fd20c