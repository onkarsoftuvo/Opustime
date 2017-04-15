class BillableItemsTaxSetting < ActiveRecord::Base
  belongs_to :billable_item
  belongs_to :tax_setting
end
