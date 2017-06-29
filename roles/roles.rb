#test 2
module Roles
  SUPER_USER = 'super_user'
  ADMINISTRATOR = 'administrator'
  READ_ONLY = 'read_only'
  EDITOR = 'editor'
  REVIEWER = 'reviewer'
  APPROVER = 'approver'
  DEPLOYMENT_MANAGER = 'deployment_manager'
  VUID_REQUESTOR = 'vuid_requestor'
  NTRT = 'ntrt'
  ALL_ROLES = [SUPER_USER, ADMINISTRATOR, READ_ONLY, EDITOR, REVIEWER, APPROVER, DEPLOYMENT_MANAGER, VUID_REQUESTOR, NTRT]
  # add the role text to views\admin_user_edit\list.html.erb in PRISME

  #causes a pundit method called any_administrator? to dynamically show up.
  COMPOSITE_ROLES = {
      any_administrator: [SUPER_USER, ADMINISTRATOR],
      can_add_comments: [SUPER_USER, EDITOR, REVIEWER, APPROVER],
      can_edit_concept: [SUPER_USER, EDITOR],
      can_deploy: [SUPER_USER, DEPLOYMENT_MANAGER],
      can_get_vuids: [SUPER_USER, VUID_REQUESTOR],
      can_ntrt: [SUPER_USER, NTRT],
  }

  def self.gui_string(role)
    case role
      when NTRT
        'NTRT'
      when VUID_REQUESTOR
        'VUID Requestor'
      else
        role.split('_').map(&:capitalize).join(' ')
    end
  end

  def self.valid_role?(role)
    ALL_ROLES.include? role
  end
end

#for Komet only
module PunditDynamicRoles

  def self.add_policy_methods(on, controller)
    #on is an instance of RolePolicy
    Roles::ALL_ROLES.each do |role|
      on.define_singleton_method("#{role}?".to_sym) do
        puser = controller.pundit_user
        roles = puser[:roles]
        user = puser[:user]
        $log.trace("The user is #{user}, the roles are #{roles}")
        user_roles = roles.nil? ? [] : roles
        sufficient_permissions = (user_roles.include? role) || (user_roles.include? Roles::SUPER_USER)
        controller.flash_alert_insufficient_privileges unless sufficient_permissions
        sufficient_permissions
      end
    end

    Roles::COMPOSITE_ROLES.each do |roles|
      method = (roles.first.to_s + '?').to_sym
      roles_array = roles.last
      on.define_singleton_method method do
        puser = controller.pundit_user
        roles = puser[:roles]
        user_roles = roles.nil? ? [] : roles
        sufficient_permissions = !(user_roles & roles_array).empty?
        controller.flash_alert_insufficient_privileges unless sufficient_permissions
        sufficient_permissions
      end
    end
  end

  def self.add_action_methods(on)
    #on is a controller
    #dynamically add authorization methods
    (Roles::ALL_ROLES + Roles::COMPOSITE_ROLES.keys).each do |role|
      method = "#{role}".to_sym
      on.define_singleton_method(method) do
        authorize :role, method
      end
      method = "#{role}?".to_sym
      on.define_singleton_method(method) do
        user_roles = on.pundit_user[:roles].nil? ? [] : on.pundit_user[:roles]
        base_role = user_roles.include? role
        composite_role_array = Roles::COMPOSITE_ROLES[role].nil? ? [] : Roles::COMPOSITE_ROLES[role]
        composite_role = (user_roles & composite_role_array).empty?# if (Roles::COMPOSITE_ROLES.key? role)
        base_role || !composite_role
      end
    end
  end
end

=begin
#with dev_box salt
token = %q{%5B%225-i%3B%5CxD2b%5Cx1F%3DA%7E%5CxBD%5CxB8%5CxCBl%5Cx96T%22%2C+%22%3Ej%5C%22e%5CxD2%3CK%7B%5Cx18%3D%5CxE9%5CxB6%5CxC5%3A%5Cx81T%22%2C+%22%2Fbe%7D%5CxCAzM%7E%5Cx19%3B%5CxFC%5CxE4%5CxA9%5Cx7F%5Cx82T%
#with test salt.
token = %q{%5B%22L%5CxE3%5CxE9%5CxFB%5Cx96%5CxCD%5CxD4%5CxC9D%5Cx84%5CxFE%5CxE7%5CxDCM%5Cx11%5Cx93%22%2C+%22G%5CxA4%5CxA2%5CxA5%5Cx96%5Cx93%5Cx80%5Cx8F%5Cx1D%5CxC7%5CxAA%5CxE9%5CxD2%5Ce%5Cx06%5Cx93%22%2C+%22V%5CxAC%5CxE5%5CxBD%5Cx8E%5CxD5%5Cx86%5Cx8A%5Cx1C%5CxC1%5CxBF%5CxBB%5CxBE%5E%5Cx05%5Cx93%22%2C+%22V%5CxA8%5CxEC%5CxB1%5CxD7%5Cx98%5Cx88%5CxDB%5Ct%5CxB3%5CxC8%5CxCC%5CxF9%3Eo%5Cx95%22%5D}


url = 'http://localhost:3000/roles/get_roles_by_token.json'

java.net.URLEncoder.encode(token, java.nio.charset.StandardCharsets::UTF_8.name).eql? token #will  be false
decoded = java.net.URLDecoder.decode(token, java.nio.charset.StandardCharsets::UTF_8.name)
decoded = java.net.URLDecoder.decode(good, java.nio.charset.StandardCharsets::UTF_8.name)
java.net.URLEncoder.encode(decoded, java.nio.charset.StandardCharsets::UTF_8.name).eql? token #will be true
java.net.URLEncoder.encode(un, java.nio.charset.StandardCharsets::UTF_8.name).eql? token #will be true

url_j = java.net.URL.new("#{url}?token=#{token}")

con = url_j.openConnection
con.setRequestMethod("GET")
responseCode = con.getResponseCode
stream = con.getInputStream
br = java.io.BufferedReader.new(java.io.InputStreamReader.new(stream))
data = br.readLine
JSON.parse data
=end