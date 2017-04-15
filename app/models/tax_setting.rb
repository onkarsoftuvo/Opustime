class TaxSetting < ActiveRecord::Base
  belongs_to :company
  # has_many :qbo_tax_rates,:dependent => :destroy

#   later validations 

  has_many :tax_settings_products , :dependent=> :destroy
  has_many :products, :through => :tax_settings_products, :dependent => :destroy
  has_many :billable_items_tax_settings , :dependent=> :destroy
  has_many :billable_items, :through => :billable_items_tax_settings, :dependent => :destroy 
  has_many :billable_items_tax_settings , :dependent=> :destroy
  has_many :billable_items, :through => :billable_items_tax_settings, :dependent => :destroy
  # Adding for Quickbooks taxes
  serialize :tax_rate_data,JSON

  validates :name , presence: true
  validates :amount , numericality: { only_integer: false ,
                :greater_than=> 0 , :less_than=> 4000000000 }
            

# ending here 
  
end
