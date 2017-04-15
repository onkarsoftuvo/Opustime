class Expense < ActiveRecord::Base
  include PublicActivity::Model
  tracked owner: Proc.new { |controller, model| controller.current_user ? controller.current_user : nil },
          company: Proc.new { |controller, model| model.company },
          business_id: Proc.new { |controller, model| model.business.try(:id) }

  audited allow_mass_assignment: true
  has_associated_audits

  belongs_to :company
  belongs_to :user

  has_many :expense_products, :dependent => :destroy

  has_many :expense_products, :dependent => :destroy

  has_one :expense_vendors_expense, :dependent => :destroy
  has_one :expense_vendor, :through => :expense_vendors_expense, :dependent => :destroy
  accepts_nested_attributes_for :expense_vendors_expense, :allow_destroy => true

  has_one :expense_categories_expense, :dependent => :destroy
  has_one :expense_category, :through => :expense_categories_expense, :dependent => :destroy
  accepts_nested_attributes_for :expense_categories_expense, :allow_destroy => true

  has_one :businesses_expense, :dependent => :destroy
  has_one :business, :through => :businesses_expense, :dependent => :destroy
  accepts_nested_attributes_for :businesses_expense, :allow_destroy => true


  accepts_nested_attributes_for :expense_products, :reject_if => lambda { |a| a[:unit_cost_price].blank? || a[:quantity].blank? }, :allow_destroy => true

  validates_associated :expense_products, if: "status == true"
  validates_presence_of :expense_products, :message => "Invalid details", if: "include_product_price == true"

  validates :total_expense, presence: true, numericality: true
  validates :tax_amount, numericality: true, :allow => nil, unless: "tax.nil? || tax.blank? "

  validates :expense_date, :presence => true

  scope :active_expense, -> { where(status: "active") }
  scope :specific_attributes, -> { select("id, expense_date , vendor, category, total_expense , tax_amount , note  , sub_amount ,created_by") }

  before_create :set_subprice

  # Quickbooks callback
  after_commit :sync_expense_with_qbo, :on => [:create, :update], :if => Proc.new { $qbo_credentials.present? }

  def sync_expense_with_qbo
    expense = Intuit::OpustimeExpense.new(self.id, $token, $secret, $realm_id)
    expense.sync
  end

  before_save :change_status_expense_products, if: :status_changed?
  self.per_page = 30

  def change_status_expense_products
    status = self.status
    expense_products = self.expense_products
    expense_products.each do |exp_prod|
      exp_prod.update_attributes(:status => false)
    end

  end

  def set_subprice
    if self.tax_amount.nil?
      self.tax_amount = 0.00
    end
    self.sub_amount = self.total_expense - self.tax_amount
  end

  def set_created_by(user_id)
    user = User.find(user_id)
    self.created_by = user.full_name
  end

  def get_tax_name
    tax_id = self.tax
    name = ""
    unless tax_id.to_i <= 0
      name = TaxSetting.find(tax_id).try(:name)
    end
    return name
  end

  def business_info
    self.business.try(:name)
  end

  def next_expense
    comp = self.company
    expense_ids = comp.expenses.active_expense.order("created_at desc").ids
    ele_index = expense_ids.index(self.id)
    next_elem = expense_ids.at(ele_index + 1)
    return next_elem


  end

  def prev_expense
    comp = self.company
    expense_ids = comp.expenses.active_expense.order("created_at desc").ids
    ele_index = expense_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : expense_ids.at(prev))
    return prev_elem
  end

  def create_activity_log(current_person)
    "#{current_person.full_name} has created an expense - ##{"0"*(6-self.id.to_s.length)+ self.id.to_s} of total_expense - #{self.total_expense} at Location - #{self.business.full_address}"
  end

  def update_activity_log(current_person)
    "#{current_person.full_name} has updated an expense - ##{"0"*(6-self.id.to_s.length)+ self.id.to_s} at location - #{self.business.full_address}"
  end

  def formatted_id
    "0"*(6-self.id.to_s.length)+ self.id.to_s
  end

  def update_activity_log
    msg = {}
    changes = self.audits.last.audited_changes
    if changes.keys.include? "total_expense"
      msg[:old_amount] = changes["total_expense"].first
      msg[:new_amount] = changes["total_expense"].second
    else
      msg = nil
    end
    return msg
  end


end