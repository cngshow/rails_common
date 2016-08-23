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

  #session tags
  SESSION_ROLES_ROOT = :roles_root
  SESSION_USER_ROLES = :current_user_roles
  SESSION_USER = :current_user
  SESSION_PASSWORD = :current_password
  SESSION_LAST_ROLE_CHECK = :last_role_check

  def self.valid_role?(role)
    ALL_ROLES.include? role
  end
end
