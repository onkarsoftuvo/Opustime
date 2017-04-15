class UserinfoPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner
  serialize :userinfo_view, JSON
  serialize :userinfo_edit, JSON
  serialize :userinfo_cru, JSON
  scope :specific_attr , ->{ select('userinfo_view , userinfo_edit , userinfo_cru')}

end
