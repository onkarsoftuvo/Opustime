class ContactPermission < ActiveRecord::Base
  include PermissionFormat
  belongs_to :owner

  serialize :contact_view , JSON
  serialize :contact_create , JSON
  serialize :contact_edit , JSON
  serialize :contact_delete , JSON

  scope :specific_attr , ->{ select('contact_view , contact_create , contact_edit , contact_delete ')}
end
