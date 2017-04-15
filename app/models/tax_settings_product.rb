class TaxSettingsProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :tax_setting
end
