require './lib/rails_common/roles/roles'

module SSOI

  SSOI_USER = :ssoi_user_model
  SSOI_HEADER = :ssoi_header
  SSOI_ADSAMACCOUNTNAME = 'HTTP_ADSAMACCOUNTNAME'

  def ssoi_headers
    session[Roles::SESSION_ROLES_ROOT] ||= {}
    ssoi_user_name = request.headers[SSOI_ADSAMACCOUNTNAME]
    $log.debug("ssoi user is #{ssoi_user_name}")
    return nil if ssoi_user_name.to_s.strip.empty?
    session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_USER] = ssoi_user_name
    session[Roles::SESSION_ROLES_ROOT][Roles::SESSION_PASSWORD] = nil
    $log.debug("The SSOI user is #{ssoi_user_name}")
    return ssoi_user_name
  end
end