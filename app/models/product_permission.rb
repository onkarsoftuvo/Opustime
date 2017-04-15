class ProductPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner
  serialize :product_view , JSON
  serialize :product_create , JSON
  serialize :product_edit , JSON
  serialize :product_stock , JSON
  serialize :product_delete , JSON

  scope :specific_attr , ->{ select('product_view , product_create , product_edit , product_stock , product_delete')}
end
