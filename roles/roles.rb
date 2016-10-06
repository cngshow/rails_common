module Roles
  SUPER_USER = 'super_user'
  ADMINISTRATOR = 'administrator'
  READ_ONLY = 'read_only'
  EDITOR = 'editor'
  REVIEWER = 'reviewer'
  APPROVER = 'approver'
  MANAGER = 'manager'

  ALL_ROLES = [SUPER_USER, ADMINISTRATOR, READ_ONLY, EDITOR, REVIEWER, APPROVER, MANAGER]

  #causes a pundit method called any_administrator? to dynamically show up.
  COMPOSITE_ROLES = {
      any_administrator: [ADMINISTRATOR, SUPER_USER],
      can_add_comments: [EDITOR, REVIEWER, APPROVER, MANAGER]
  }

  def self.valid_role?(role)
    ALL_ROLES.include? role
  end
end

module PunditDynamicRoles

  def self.add_policy_methods(on, user_and_roles)

    Roles::ALL_ROLES.each do |role|
      on.define_singleton_method("#{role}?".to_sym) do
        $log.debug("The user is #{user_and_roles[:user]}, the roles are #{user_and_roles[:roles]}")
        user_roles = user_and_roles[:roles].nil? ? [] : user_and_roles[:roles]
        (user_roles.include? role) || (user_roles.include? Roles::SUPER_USER)
      end
    end

    Roles::COMPOSITE_ROLES.each do |roles|
      method = (roles.first.to_s + '?').to_sym
      roles_array = roles.last
      on.define_singleton_method method do
        user_roles = user_and_roles[:roles].nil? ? [] : user_and_roles[:roles]
        !(user_roles & roles_array).empty?
      end
    end

  end

  def self.add_controller_methods(on)
    #dynamically add authorization methods
    (Roles::ALL_ROLES + Roles::COMPOSITE_ROLES.keys).each do |role|
      method = "#{role}?".to_sym
      on.define_singleton_method(method) do
        authorize :role, method
      end
    end
  end
end
