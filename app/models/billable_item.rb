class BillableItem < ActiveRecord::Base
  serialize :concession_price , Array
  
  belongs_to :company
  
  # has_many :concessions , :through=> :company
  # has_and_belongs_to_many :concessions , :dependent=> :destroy
  has_many :billable_items_concessions , :dependent=> :destroy
  has_many :concessions , :through=> :billable_items_concessions ,  :dependent=> :destroy
  accepts_nested_attributes_for :billable_items_concessions , :allow_destroy => true
  
  #Edited by Manoranjan
  has_one :billable_items_tax_setting , :dependent=> :destroy
  has_one :tax_setting, :through => :billable_items_tax_setting, :dependent => :destroy
  accepts_nested_attributes_for :billable_items_tax_setting, :allow_destroy => true
  
  has_many :appointment_types_billable_items , :dependent=> :destroy
  has_many :appointment_types , :through=> :appointment_types_billable_items  ,  :dependent=> :destroy
  has_many :invoice_items, :as => :item , :dependent => :destroy
  
#   later validations 
  validates_presence_of :name 
  validates :price , presence: true , numericality: {:greater_than=> 0}
  validates :tax , presence: true , if: Proc.new {|a| a.include_tax == true}
  before_create :check_item_type

  # Quickbooks callback
  after_commit :sync_billable_item_with_qbo,:on=>[:create,:update],:if=>Proc.new{ $qbo_credentials.present? }
  after_create :set_tax_setting

  def sync_billable_item_with_qbo
    service = Intuit::OpustimeProductAndService.new(self.id,self.class,$token,$secret,$realm_id,$qbo_credentials.id)
    service.sync
  end

  def set_tax_setting
    if self.tax.to_i > 0 && self.tax_setting.nil?
      comp = self.company
      tax_setting = comp.tax_settings.find_by_id(self.tax.to_i)
      BillableItemsTaxSetting.create(billable_item_id: self.id , tax_setting_id: tax_setting.id ) unless tax_setting.nil?
    end
  end

  def tax_name
    tax_id = self.tax.to_i
    tax_name = ""
    if tax_id > 0
      tax_name = TaxSetting.find_by_id(tax_id).try(:name)
    end
    return tax_name
  end

  def tax_amount
    tax_id = self.tax.to_i
    tax_val = 0.0
    if tax_id > 0
      tax_val = TaxSetting.find_by_id(tax_id).try(:amount)
    end
    return tax_val
  end

  def get_price
    tax_id = self.tax.to_i
    purchase_price = 0.0
    if tax_id > 0 && self.include_tax
      tax_val  = TaxSetting.find_by_id(tax_id).try(:amount)
      applied_tax = (self.price.to_i * tax_val) / 100
      purchase_price = (self.price.to_i - applied_tax)
    else
      purchase_price = self.price 
    end
    return purchase_price
  end

  def check_item_type
    unless [true , false].include?(self.item_type)
      self.item_type = true
    end
  end
  
end
