class AnnouncemsgPermission < ActiveRecord::Base
  include PermissionFormat


  belongs_to :owner
  serialize :announcemsg_crud , JSON
  serialize :announcemsg_comment , JSON
  scope :specific_attr , ->{ select('announcemsg_crud , announcemsg_comment')}
end
