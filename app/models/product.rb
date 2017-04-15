class Product < ActiveRecord::Base
  belongs_to :company
  has_many :product_stocks, :dependent => :destroy

  has_many :appointment_types_products, :dependent => :destroy
  has_many :appointment_types, :through => :appointment_types_products, :dependent => :destroy
  attr_accessor :include_tax

  has_many :invoice_items, :as => :item, :dependent => :destroy

  has_one :tax_settings_product, :dependent => :destroy
  has_one :tax_setting, :through => :tax_settings_product, :dependent => :destroy
  accepts_nested_attributes_for :tax_settings_product, :allow_destroy => true

  scope :is_tax_included?, ->(product) { (product.price_inc_tax - product.price_exc_tax) > 0 ? true : false }

  validates :name, presence: true
  validates :price, numericality: {:greater_than_or_equal_to => 0}, :presence => true
  validates :cost_price, numericality: {:greater_than_or_equal_to => 0}, :allow_nil => true
  # validates :include_tax, inclusion: { in: [true, false] }

  validates :stock_number, numericality: {only_integer: true, :greater_than => 0}, :allow_nil => true
  validates_presence_of :tax, :message => "Tax must be selected if including tax in price", if: Proc.new { |a| a.include_tax == true || a.tax=="N/A" }

  # scope specific_attributes, ->{ select("id ,item_code , name , serial_no , price_inc_tax , price_exc_tax , tax , cost_price , stock_number , note , price , supplier")}
  scope :active_products, -> { where(status: true) }
  self.per_page = 30


  before_create :set_prices
  before_update :set_prices
  before_create :set_status
  after_create :set_tax_setting

  # Quickbooks callback
  after_commit :sync_product_with_qbo, :on => [:create, :update], :if => Proc.new { |product| product.status && $qbo_credentials.present? }

  def sync_product_with_qbo
    product = Intuit::OpustimeProductAndService.new(self.id, self.class, $token, $secret, $realm_id, $qbo_credentials.id)
    product.sync
  end

  def set_status
    self.status = true
  end

  def set_tax_setting
    if self.tax.to_i > 0 && self.tax_setting.nil?
      comp = self.company
      tax_setting = comp.tax_settings.find_by_id(self.tax.to_i)
      TaxSettingsProduct.create(product_id: self.id , tax_setting_id: tax_setting.id ) unless tax_setting.nil?
    end
  end

  def set_prices
    #Edited by Manoranjan

    # tax_amount = self.tax_setting.try(:amount)
    tax_amount = TaxSetting.find_by_id(self.tax).try(:amount)
    if include_tax == true && !tax_amount.nil?
      self.price_exc_tax = ((price.to_f)/(1 + (tax_amount/100.0))) #.round(2)
      self.price_inc_tax = price
    else
      if !tax_amount.nil?
        self.price_exc_tax = price
        self.price_inc_tax = ((price.to_f)*(1 + (tax_amount/100.0))) #.round(2)
      else
        self.price_exc_tax = price
        self.price_inc_tax = price
      end

    end
    self.price = self.price_exc_tax
  end

  def create_stock(user_id)
    current_user = User.find(user_id)
    product_stock = self.product_stocks.new(stock_level: true, stock_type: "Initial Stock Level", quantity: self.stock_number, adjusted_at: Date.today, adjusted_by: current_user.try(:id))
    if product_stock.valid?
      product_stock.save
    end
  end

  def get_tax_name
    tax_id = self.id
    name = " "
    unless tax_id.nil?
      name = TaxSetting.find(tax_id).try(name).to_s rescue ""
    end
    return name
  end

  def next_product
    comp = self.company
    prods_ids = comp.products.order("created_at desc").ids
    ele_index = prods_ids.index(self.id)
    next_elem = prods_ids.at(ele_index + 1)
    return next_elem


  end

  def prev_product
    comp = self.company
    prods_ids = comp.products.order("created_at desc").ids
    ele_index = prods_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : prods_ids.at(prev))
    return prev_elem

  end


end
