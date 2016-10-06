module SSOI
  def ssoi_headers
    ssoi_login = request.headers['HTTP_ADSAMACCOUNTNAME']
    $log.debug("ssoi user is #{ssoi_login}")
    return nil if ssoi_login.to_s.strip.empty?

    user_session(UserSession::LOGIN, ssoi_login)
    user_session(UserSession::PWD, nil)
=begin
    user_session(UserSession::EMAIL, request.headers['HTTP_ADEMAIL'])

    # pull out the user name which is returned in the form...
    # CN=Bowman\, Gregory,OU=Contractors,OU=Remote Users,OU=Users,OU=Birmingham (ISB),OU=Field Offices,DC=vha,DC=med,DC=va,DC=gov
    lname, fname = '', ''
    name = request.headers['HTTP_SM_USER']

    if name
      matches = name.match(/CN=(.*?)\\,\s(.*?)\,OU=/)
      lname, fname = matches.captures unless matches.nil?
    end

    user_session(UserSession::USER_NAME, [fname, lname].join(' ').strip)
=end
    ssoi_login
  end
end
