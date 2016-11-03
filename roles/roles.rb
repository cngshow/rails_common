module Roles
  SUPER_USER = 'super_user'
  ADMINISTRATOR = 'administrator'
  READ_ONLY = 'read_only'
  EDITOR = 'editor'
  REVIEWER = 'reviewer'
  APPROVER = 'approver'
  #MANAGER = 'manager'

  ALL_ROLES = [SUPER_USER, ADMINISTRATOR, READ_ONLY, EDITOR, REVIEWER, APPROVER]

  #causes a pundit method called any_administrator? to dynamically show up.
  COMPOSITE_ROLES = {
      any_administrator: [SUPER_USER, ADMINISTRATOR],
      can_add_comments: [SUPER_USER, EDITOR, REVIEWER, APPROVER],
      can_edit_concept: [SUPER_USER, EDITOR],
  }

  def self.valid_role?(role)
    ALL_ROLES.include? role
  end
end

module PunditDynamicRoles

  def self.add_policy_methods(on, user_and_roles)

    Roles::ALL_ROLES.each do |role|
      on.define_singleton_method("#{role}?".to_sym) do
        $log.trace("The user is #{user_and_roles[:user]}, the roles are #{user_and_roles[:roles]}")
        user_roles = user_and_roles[:roles].nil? ? [] : user_and_roles[:roles]
        sufficient_permissions = (user_roles.include? role) || (user_roles.include? Roles::SUPER_USER)
        user_and_roles[:controller_instance].flash_alert_insufficient_privileges unless sufficient_permissions
        sufficient_permissions
      end
    end

    Roles::COMPOSITE_ROLES.each do |roles|
      method = (roles.first.to_s + '?').to_sym
      roles_array = roles.last
      on.define_singleton_method method do
        user_roles = user_and_roles[:roles].nil? ? [] : user_and_roles[:roles]
        sufficient_permissions = !(user_roles & roles_array).empty?
        user_and_roles[:controller_instance].flash_alert_insufficient_privileges unless sufficient_permissions
        sufficient_permissions
      end
    end
  end

  def self.add_action_methods(on)
    #dynamically add authorization methods
    (Roles::ALL_ROLES + Roles::COMPOSITE_ROLES.keys).each do |role|
      method = "#{role}".to_sym
      on.define_singleton_method(method) do
        authorize :role, method
      end
      method = "#{role}?".to_sym
      on.define_singleton_method(method) do
        user_roles = on.pundit_user[:roles]
        base_role = user_roles.include? role
        composite_role = (user_roles & Roles::COMPOSITE_ROLES[role]).empty? if (Roles::COMPOSITE_ROLES.key? role)
        base_role || !composite_role
      end
      begin
        ApplicationController.helper_method method
      rescue => ex
        $log.error("On role #{role} I could not add the helper method #{method}, #{ex}")
        $log.error(ex.backtrace.join("\n"))
      end
    end
  end
end
