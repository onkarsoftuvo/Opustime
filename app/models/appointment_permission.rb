class AppointmentPermission < ActiveRecord::Base
  include PermissionFormat
  belongs_to :owner

  serialize :apnt_view , JSON
  serialize :apnt_create , JSON
  serialize :apnt_edit , JSON
  serialize :apnt_delete , JSON

  scope :specific_attr , ->{ select('apnt_view , apnt_create , apnt_edit , apnt_delete')}

end
