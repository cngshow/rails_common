require './lib/rails_common/roles/roles'

module SSOI

  SSOI_USER = :ssoi_user_model
  SSOI_USER_STRING = :ssoi_user
  SSOI_HEADER = :ssoi_header
  SSOI_ADSAMACCOUNTNAME = 'HTTP_ADSAMACCOUNTNAME'

  def ssoi_headers
    session[Roles::SESSION_ROLES_ROOT] ||= {}
    ssoi_user_name = request.headers[SSOI_ADSAMACCOUNTNAME]
    return if ssoi_user_name.to_s.strip.empty?
    session[Roles::SESSION_ROLES_ROOT][SSOI_USER_STRING] = ssoi_user_name
    $log.debug("The SSOI user is #{ssoi_user_name}")
    return ssoi_user_name
  end
end