class UserRolesOwner < ActiveRecord::Base
  belongs_to :owner
  belongs_to :user_role
end
