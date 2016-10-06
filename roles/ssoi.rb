module SSOI
  def ssoi_headers
    ssoi_user_name = request.headers['HTTP_ADSAMACCOUNTNAME']
    $log.debug("ssoi user is #{ssoi_user_name}")
    return nil if ssoi_user_name.to_s.strip.empty?

    user_session(UserSession::LOGIN, ssoi_user_name)
    user_session(UserSession::PWD, nil)
    ssoi_user_name
  end
end
