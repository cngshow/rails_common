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
