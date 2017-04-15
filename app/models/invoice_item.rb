class InvoiceItem < ActiveRecord::Base
  audited associated_with: :invoice

  belongs_to :invoice
  belongs_to :item, :polymorphic => true

  validate :check_stocks_quantity, :if => Proc.new { |invoice_item| invoice_item.item.class.to_s.eql?('Product') }
  validates :item_id, presence: true
  validates :quantity, presence: true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :unit_price, :numericality => {:greater_than => 0}
  validates :discount, :numericality => {:greater_than_or_equal_to => 0}, allow_nil: true, allow_blank: true

  def check_stocks_quantity
    if self.item.class.name.eql? "Product"
      unless self.item.stock_number > 0 && self.item.stock_number >= self.quantity
        self.errors.add(:Quantity, "is much bigger from stocks")
      end
    end
  end

  def get_item_code
    parent_obj = self.item_id
    item_code = " "
    unless parent_obj.to_i <= 0
      if self.item_type == "Product"
        item = Product.find_by_id(parent_obj)
      else
        item = BillableItem.find_by_id(parent_obj)
      end

      item_code = item.item_code unless item.nil?
    end
    return item_code
  end

  def get_item_name
    parent_obj = self.item_id
    name = " "
    unless parent_obj.to_i <= 0
      if self.item_type == "Product"
        item = Product.find_by_id(parent_obj)
      else
        item = BillableItem.find_by_id(parent_obj)
      end

      name = item.name unless item.nil?
    end
    return name
  end

  def get_tax_id(comp, tax_name)
    tax_name = comp.tax_settings.where(["name = ?", tax_name]).first.try(:id)
  end

  def get_concession_name
    cs_id = self.concession
    name = " "
    if cs_id.to_i >0
      name = Concession.find_by_id(cs_id).try(:name)
    end
    return name
  end

  def discount_amount
    discount_amount = 0
    unless self.discount.nil?
      amount_with_tax = (self.unit_price * self.tax_amount.to_i)*self.quantity/100 + self.unit_price
      if self.discount_type_percentage == "%"
        discount_amount = (amount_with_tax * self.discount)/100.0
      else
        discount_amount = (self.discount)
      end
    end
    return discount_amount

  end

end
