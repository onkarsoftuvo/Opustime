class UserRole < ActiveRecord::Base
  has_many :user_roles_users , :dependent => :destroy
  has_many :users , :through => :user_roles_users , :dependent => :destroy
  has_many :permissions , :dependent => :destroy

  has_many :user_roles_owners , :dependent => :destroy
  has_many :owners , :through => :user_roles_owners , :dependent => :destroy

  has_one :admin_permission

end
