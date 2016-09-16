module Roles

  #good roles.
  SUPER_USER = :super_user
  ADMINISTRATOR = :administrator

  #loser roles.
  READ_ONLY = :read_only
  EDITOR = :editor
  REVIEWER = :reviewer
  APPROVER = :approver
  FINAL_APPROVER = :final_approver

  ALL_ROLES = [SUPER_USER, ADMINISTRATOR, READ_ONLY, EDITOR, REVIEWER, APPROVER, FINAL_APPROVER]

  #causes a pundit method called any_aprover? to dynamically show up.
  COMPOSITE_ROLES = {any_approver: [APPROVER, FINAL_APPROVER]}

  #using strings not symbols because we are nested, see the following:
  #http://stackoverflow.com/questions/23530055/ruby-on-rails-sneakily-changing-nested-hash-keys-from-symbols-to-strings
  #session tags
  SESSION_ROLES_ROOT = 'roles_root'
  SESSION_USER_ROLES = 'current_user_roles'
  SESSION_USER = 'current_user'
  SESSION_PASSWORD = 'current_password'
  SESSION_LAST_ROLE_CHECK = 'last_role_check'

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
        user_roles.include? role
      end
    end

    Roles::COMPOSITE_ROLES.each do |roles|
      method = (roles.first.to_s + '?').to_sym
      roles_array = roles.last
      on.define_singleton_method method do
        user_roles = user_and_roles[:roles].nil? ? [] : user_and_roles[:roles]
        (user_roles & roles_array).empty?
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
