module UserSession
  #using strings not symbols because we are nested, see the following:
  #http://stackoverflow.com/questions/23530055/ruby-on-rails-sneakily-changing-nested-hash-keys-from-symbols-to-strings

  # user session constants
  LAST_ROLE_CHECK = 'last_role_check'
  TOKEN = 'user_token'
  LOGIN = 'user_login'
  PWD = 'user_password'
  ROLES = 'user_roles'
  SSOI_USER = 'ssoi_user'
  ALL_USER_SESSION_VARS = [LAST_ROLE_CHECK, TOKEN, LOGIN, PWD, ROLES, SSOI_USER]

  def user_session_defined?
    ! _session.empty?
  end

  def clear_user_session
    _session.clear
  end

  def user_session(*args)
    begin
      raise 'Invalid call to user_session. Too many arguments passed' if args.empty? || args.length > 2
      key = args.first
      unless valid_key? key
        raise 'Invalid key argument passed. Use the constants in UserSession to access the user_session data'
      end

      if args.length == 1
        _session[key]
      else
        _session[key] = args.last
      end
    end
  end

  private
  def _session
    session['user_data'] ||= {}
  end

  def valid_key?(key)
    ALL_USER_SESSION_VARS.include?(key)
  end
end
