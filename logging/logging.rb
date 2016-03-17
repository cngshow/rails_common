require 'logging'
# here we setup a color scheme called 'bright'

#Logging.caller_tracing=true
Logging.init :debug, :info, :warn, :error, :fatal, :always

Logging.color_scheme('pretty',
                     levels: {
                         :info => :green,
                         :warn => :yellow,
                         :error => :red,
                         :fatal => [:white, :on_red],
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
    filename: $PROPS['LOG.filename'],
    truncate: true
)

begin

  $log = ::Logging::Logger['MainLogger']
  $log.caller_tracing=$PROPS['LOG.caller_tracing'].upcase.eql?('TRUE')

  $log.add_appenders 'stdout' unless $PROPS['LOG.append_stdout'].nil?
  $log.add_appenders rf
  $log.level = $PROPS['LOG.level'].downcase.to_sym

# these log messages will be nicely colored
# the level will be colored differently for each message
#
  unless ( File.basename($0) == 'rake')
    $log.always 'Logging started!'
  end
rescue => ex
  warn "Logger failed to initialize.  Reason is #{ex.to_s}"
  warn ex.backtrace.join("\n")
  warn 'Shutting down the KOMET web server!'
  java.lang.System.exit(1)
end
