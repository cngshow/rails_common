module BootstrapNotifier

  INSUFFICIENT_PRIVILEGES = 'Insufficient privileges!<br>Please refresh your browser!'
  ROLE_CHANGE = 'Your roles have changed.<br> Please refresh your browser as soon as possible.'

  def show_flash
    ret = _bs_session.clone.uniq
    _bs_session.clear
    ret
  end

  def flash_notify(message:)
    _bs_session << {options: {message: message}, settings: {type: 'success'}}
  end

  def flash_alert(message:)
    _bs_session << {options: {message: message}, settings: {type: 'danger', delay: 0}}
  end

  private
  def _bs_session
    session['bs_notifier'] ||= []
  end
end
