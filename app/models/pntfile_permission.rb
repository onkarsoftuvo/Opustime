class PntfilePermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :pntfile_upload , JSON
  serialize :pntfile_viewname , JSON
  serialize :pntfile_view , JSON
  serialize :pntfile_update , JSON
  serialize :pntfile_delown , JSON
  serialize :pntfile_delall ,JSON
  scope :specific_attr , ->{ select('pntfile_upload , pntfile_viewname , pntfile_view , pntfile_update , pntfile_delown , pntfile_delall')}
end
