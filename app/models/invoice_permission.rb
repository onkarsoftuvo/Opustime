class InvoicePermission < ActiveRecord::Base
  include PermissionFormat
  belongs_to :owner

  serialize :invoice_view , JSON
  serialize :invoice_create , JSON
  serialize :invoice_edit , JSON
  serialize :invoice_delete , JSON

  scope :specific_attr , ->{ select('invoice_view , invoice_create , invoice_edit , invoice_delete')}
end
