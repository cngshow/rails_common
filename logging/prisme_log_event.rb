require 'faraday'
# load('./lib/rails_common/logging/prisme_log_event.rb')
module PrismeLogEvent

  LEVELS = {ALWAYS: 1, WARN: 2, ERROR: 3, FATAL: 4}

  #Add your tags here.  Keep in mind these may one day show up in a dropdown for filteration purposes in prisme.  Keep the domain small.
  LIFECYCLE_TAG = 'LIFE_CYCLE'
  CHECKSUM_TAG = 'CHECKSUM'

  def self.notify(tag, message, asynchronous = true)
    begin
      level_used = caller_locations(2,1)[0].label.upcase
      $log.warn("The log with tag #{tag} and message -->#{message}<-- will not be sent to the LogEvent table. You must make my call in block form!! {}'s not ().'") unless Logging::RAILS_COMMON_LEVELS.include? level_used.downcase.to_sym
      level_int = LEVELS[level_used.to_sym]
      #$log.fatal "level_int is #{level_int}, level_used is #{level_used}"
      send(tag, message.to_s, level_int, level_used.downcase.to_sym, asynchronous) if level_int
    rescue => ex
      $log.warn("Something went wrong... I cannot notify prisme's log event's #{ex}")
      $log.warn(ex.backtrace.join("\n"))
    end
    message
  end

  private
  def self.send(tag, message, level, level_used_sym, asynchronous)
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
      if url.nil?
        $log.warn("This application is not properly configured! Missing key PRISME.prisme_notify_url in the property file.  Was this application deployed by prisme?")
        return
      end
      runnable = -> do
        begin
          response = FaradayUtilities::CONNECTION_JSON.post do |req|
            req.body = {application_name: Rails.application.class.parent_name, level: level, tag: tag, message: message}
            req.url url
          end
          result_hash = JSON.parse response.body
          event_logged = result_hash['event_logged']
          if event_logged
            $log.info('Notification sent! (Success)')
          else
            $log.warn('Notification was sent, but not accepted!  Validation errors: ' + result_hash['validation_errors'].inspect)
          end
        rescue => ex
          log_error(ex, level_used_sym, tag, message)
        end
      end
      if asynchronous
        Thread.new do
          runnable.call
        end
      else
        runnable.call
      end
    end
  end

  def self.log_error(ex, level_used_sym, tag, message)
    $log.send level_used_sym, "Failed to notify a prisme log event, tag=#{tag}, message='#{message}'"
    $log.send level_used_sym, "The error was #{ex}"
    $log.send level_used_sym, ex.backtrace.join("\n")
  end
end

PrismeLogEvent::LEVELS.keys.map do |k| k.to_s.downcase end.each do |level|
  $log.define_singleton_method((level+'_n').to_sym) do |*args|
    $log.send level.to_sym do
      tag = args.shift
      message = args.shift
      asynchronous = args.shift
      PrismeLogEvent.notify(tag, message, asynchronous) unless asynchronous.nil?
      PrismeLogEvent.notify(tag, message) if asynchronous.nil?
      loc = caller_locations(3,1).first.path.to_s
      line = caller_locations(3,1).first.lineno.to_s
      loc.gsub!(Rails.root.to_s.gsub('\\','/'),'')
      "[original location: #{loc},[#{line}][tag: #{tag}] #{message}"
    end
  end
end
# $log.warn_n('gigglesz', "Evil Cris")