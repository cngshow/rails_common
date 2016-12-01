require 'faraday'
# load('./lib/rails_common/logging/prisme_log_event.rb')
module PrismeLogEvent

  LEVELS = {ALWAYS: 1, WARN: 2, ERROR: 3, FATAL: 4}
  LIFECYCLE_TAG = 'LIFE_CYCLE'

  CONNECTION = Faraday.new do |faraday|
    faraday.request :url_encoded # form-encode POST params
    faraday.use Faraday::Response::Logger, $log
    faraday.headers['Accept'] = 'application/json'
    #faraday.use Faraday::Middleware::ParseJson
    faraday.adapter :net_http # make requests with Net::HTTP
    #faraday.request  :basic_auth, @urls[:user], @urls[:password]
  end

  def self.notify(tag, message)
    begin
      level_used = caller_locations(2,1)[0].label.upcase
      $log.warn("The log with tag #{tag} and message -->#{message}<-- will not be sent to the LogEvent table. You must make my call in block form!! {}'s not ().'") unless Logging::RAILS_COMMON_LEVELS.include? level_used.downcase.to_sym
      level_int = LEVELS[level_used.to_sym]
      #$log.fatal "level_int is #{level_int}, level_used is #{level_used}"
      send(tag, message.to_s, level_int, level_used.downcase.to_sym) if level_int
    rescue => ex
      $log.warn("Something went wrong... I cannot notify prisme's log event's #{ex}")
      $log.warn(ex.backtrace.join("\n"))
    end
    message
  end

  private
  def self.send(tag, message, level, level_used_sym)
    if Rails.application.class.parent_name.eql? 'RailsPrisme'
      #locally add to activerecord.
      begin
        LogEvent.new({hostname: Socket.gethostname, application_name: Rails.application.class.parent_name, level: level, tag: tag, message: message}).save!
      rescue => ex
        log_error(ex, level_used_sym, tag, message)
      end
    else
      #make rest call
      url = $PROPS['PRISME.prisme_notify_url']
      $log.warning("This application is not properly configured! Missing key PRISME.prisme_notify_url in the property file.  Was this application deployed by prisme?") if url.nil?
      Thread.new do
        begin
          CONNECTION.post do |req|
            req.body = {application_name: Rails.application.class.parent_name, level: level, tag: tag, message: message}
            req.url url
          end
        rescue => ex
          log_error(ex, level_used_sym, tag, message)
        end
      end
    end
  end

  def self.log_error(ex, level_used_sym, tag, message)
    $log.send level_used_sym, "Failed to notify a prisme log event, tag=#{tag}, message='#{message}'"
    $log.send level_used_sym, "The error was #{ex}"
    $log.send level_used_sym, ex.backtrace.join("\n")
  end
end

$log.always{PrismeLogEvent.notify(PrismeLogEvent::LIFECYCLE_TAG,'Prisme coming up!')}