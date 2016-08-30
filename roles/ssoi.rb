require './lib/rails_common/roles/roles'

module SSOI

  #using strings not symbols because we are nested, see the following:
  #http://stackoverflow.com/questions/23530055/ruby-on-rails-sneakily-changing-nested-hash-keys-from-symbols-to-strings
  SSOI_USER = 'ssoi_user_model'
  SSOI_ADSAMACCOUNTNAME = 'HTTP_ADSAMACCOUNTNAME'

  def ssoi_headers
    session[Roles::SESSION_ROLES_ROOT] ||= {}
    ssoi_user_name = request.headers[SSOI_ADSAMACCOUNTNAME]
    $log.debug("I have header SSOI_ADSAMACCOUNTNAME? #{request.headers.key?(SSOI_ADSAMACCOUNTNAME)}")
    $log.debug("ssoi user is #{ssoi_user_name}")

    if ssoi_user_name.to_s.strip.empty?
      session[Roles::SESSION_ROLES_ROOT] = {} if request.headers.key?(SSOI_ADSAMACCOUNTNAME)
      return nil
    end

    session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER] = ssoi_user_name
    session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_PASSWORD] = nil
    $log.debug("The SSOI user is #{ssoi_user_name}")
    ssoi_user_name
  end
end