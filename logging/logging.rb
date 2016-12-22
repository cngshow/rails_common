require 'logging'
require 'fileutils'

#if nil we are in trinidad
CATALINA_HOME = java.lang.System.properties['catalina.home']
LOG_HOME = CATALINA_HOME.nil? ? "#{Rails.root}/logs/" : "#{CATALINA_HOME}/logs/"
FileUtils::mkdir_p LOG_HOME

module Logging
  #add a level here if needed....
  RAILS_COMMON_LEVELS = [:trace, :debug, :info, :warn, :error, :fatal, :unknown, :always]
end
#Logging.caller_tracing=true
Logging.init *Logging::RAILS_COMMON_LEVELS

Logging.color_scheme('pretty',
                     levels: {
                         :info => :green,
                         :warn => :yellow,
                         :error => :red,
                         :fatal => [:white, :on_red],
                         :unknown => [:yellow, :on_blue],
                         :always => :white
                     },
                     date: :yellow,
                     #logger: :cyan,
                     #message: :magenta,
                     file: :magenta,
                     line: :cyan
)
#move pattern to prop file
pattern = $PROPS['LOG.pattern']
Logging.appenders.stdout(
    'stdout',
    :layout => Logging.layouts.pattern(
        :pattern => pattern,
        :color_scheme => 'pretty'
    )
)

rf = Logging.appenders.rolling_file(
    'file',
    layout: Logging.layouts.pattern(
        pattern: pattern,
        color_scheme: 'pretty',
    #    backtrace: true
    ),
    roll_by: $PROPS['LOG.roll_by'],
    keep: $PROPS['LOG.keep'].to_i,
    age: $PROPS['LOG.age'],
    filename: LOG_HOME + $PROPS['LOG.filename'],
    truncate: true
)

begin

  $log = ::Logging::Logger['MainLogger']
  $log.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

  $log.add_appenders 'stdout' if $PROPS['LOG.append_stdout'].eql?('true')
  $log.add_appenders rf
  $log.level = $PROPS['LOG.level'].downcase.to_sym

  unless $PROPS['LOG.filename_rails'].nil?

    #rf_rails is for rails logging
    rf_rails = Logging.appenders.rolling_file(
        'file',
        layout: Logging.layouts.pattern(
            pattern: pattern,
            color_scheme: 'pretty',
        #    backtrace: true
        ),
        roll_by: $PROPS['LOG.roll_by'],
        keep: $PROPS['LOG.keep'].to_i,
        age: $PROPS['LOG.age'],
        filename: LOG_HOME + $PROPS['LOG.filename_rails'],
        truncate: true
    )
    $log_rails = ::Logging::Logger['RailsLogger']
    $log_rails.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

    $log_rails.add_appenders 'stdout' if $PROPS['LOG.append_stdout'].eql?('true')
    $log_rails.add_appenders rf_rails
    $log_rails.level = $PROPS['LOG.level'].downcase.to_sym
  end

  unless $PROPS['LOG.filename_admin'].nil?

    #rf_rails is for rails logging
    rf_admin = Logging.appenders.rolling_file(
        'file',
        layout: Logging.layouts.pattern(
            pattern: pattern,
            color_scheme: 'pretty',
        #    backtrace: true
        ),
        roll_by: $PROPS['LOG.roll_by'],
        keep: $PROPS['LOG.keep'].to_i,
        age: $PROPS['LOG.age'],
        filename: LOG_HOME + $PROPS['LOG.filename_admin'],
        truncate: true
    )
    $alog = ::Logging::Logger['LogAdmin']
    $alog.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

    $alog.add_appenders 'stdout' if $PROPS['LOG.append_stdout'].eql?('true')
    $alog.add_appenders rf_admin
    $alog.level = $PROPS['LOG.level'].downcase.to_sym
  end


# these log messages will be nicely colored
# the level will be colored differently for each message
# PrismeLogEvent not visible yet
  unless (File.basename($0) == 'rake')
    [$log, $alog, $log_rails].each {|e| e.always 'Logging started!'}
  end
rescue => ex
  warn "Logger failed to initialize.  Reason is #{ex.to_s}"
  warn ex.backtrace.join("\n")
  warn 'Shutting down the KOMET/PRISME web server!'
  java.lang.System.exit(1)
end