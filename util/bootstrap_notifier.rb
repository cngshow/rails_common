module BootstrapNotifier

  INSUFFICIENT_PRIVILEGES = 'Insufficient privileges!<br>Please refresh your browser!'
  ROLE_CHANGE = 'Your roles have changed.<br> Please refresh your browser as soon as possible.'
  AJAX_HDR_ROLES = 'AJAX_HDR_ROLES' # this is used as a key in the response header when verifying that the komet user's roles have not changed

  RESPONSE_HEADER = 'X-flash-notifier'

  def show_flash
    return if pundit_user.nil?
    ret = _bs_session.clone.uniq
    _bs_session.clear
    pundit_user[:user].nil? ? [] : ret
    ret.to_json
  end

  def flash_notify(message:)
    flash_msg(message, {type: 'success'})
  end

  def flash_alert(message:)
    flash_msg(message, {type: 'danger', delay: 0})
  end

  def flash_info(message:)
    flash_msg(message, {type: 'info', delay: 0})
  end

  private

  # if we ever see duplicate flash messages then add thread safety to this method
  def flash_msg(message, settings = {})
    msg = HashWithIndifferentAccess.new({options: {message: message}, settings: settings.merge!(z_index: 99999)})

    if request.xhr?
      hdrs = response[RESPONSE_HEADER] ||= []
      hdrs = JSON.parse(URI.unescape(hdrs)) unless hdrs.empty?
      hdrs.map! {|m| HashWithIndifferentAccess.new(m) }
      hdrs << msg
      hdrs.uniq!
      response.headers[RESPONSE_HEADER] = URI.escape(hdrs.to_json)
    else
      _bs_session << msg
    end
  end

  def _bs_session
    s = session if self.respond_to? :session
    s = Thread.current.thread_variable_get(:komet_user_session) if s.nil?
    s['bs_notifier'] ||= []
  end
end
