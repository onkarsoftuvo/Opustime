class PaymentPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :payment_view , JSON
  serialize :payment_create , JSON
  serialize :payment_edit , JSON
  serialize :payment_delete , JSON

  scope :specific_attr , ->{ select('payment_view , payment_create , payment_edit , payment_delete')}

end
