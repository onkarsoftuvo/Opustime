class Invoice < ActiveRecord::Base
  audited allow_mass_assignment: true

  include PublicActivity::Model
  tracked owner: Proc.new { |controller, model| controller.current_user ? controller.current_user : nil },

          company: Proc.new { |controller, model| model.patient.company },
          business_id: Proc.new { |controller, model| model.business.try(:id) }

  has_associated_audits

  belongs_to :creater, :polymorphic => true
  belongs_to :updater, :polymorphic => true

  belongs_to :patient
  has_many :invoice_items, :dependent => :destroy

  has_many :invoices_payments
  has_many :payments, :through => :invoices_payments, dependent: :destroy

  has_one :appointments_invoice, :dependent => :destroy
  has_one :appointment, :through => :appointments_invoice, :dependent => :destroy
  accepts_nested_attributes_for :appointments_invoice, :allow_destroy => true

  has_one :appointment_types_invoice, :dependent => :destroy
  has_one :appointment_type, :through => :appointment_types_invoice, :dependent => :destroy
  accepts_nested_attributes_for :appointment_types_invoice, :allow_destroy => true

  has_one :businesses_invoice, :dependent => :destroy
  has_one :business, :through => :businesses_invoice, :dependent => :destroy
  accepts_nested_attributes_for :businesses_invoice, :allow_destroy => true

  has_one :invoices_user, :dependent => :destroy
  has_one :user, -> { where("is_doctor= ? AND acc_active=?", true, true) }, :through => :invoices_user, :dependent => :destroy
  accepts_nested_attributes_for :invoices_user, :allow_destroy => true

  accepts_nested_attributes_for :invoice_items, :reject_if => lambda { |a| a[:item_id].nil? || a[:item_id].blank? }, :allow_destroy => true

  # validates :patientid ,:practitioner ,:business , presence:true
  validates_associated :invoice_items
  validates_presence_of :invoice_items

  scope :active_invoice, -> { where(status: true) }

  scope :avoid_del_patient, -> { joins(:patient).where(['patients.status IN (?) ' , ['active', 'archive']]) }

  before_update :rollback_amount_to_patient_credit_amount
  after_commit :changing_payment_assoicaite_after_removing_invoice, :if => Proc.new { |k| k.status == false }

  # after_commit :check_stocks_quantity , on: [:create , :update]

  after_save :product_stock_adjustment

  after_create :auto_adjustment_payment , :if => Proc.new { |invoice| invoice.invoice_amount_was != invoice.invoice_amount && invoice.use_credit_balance }
  after_update :auto_adjustment_payment_on_update , :if => Proc.new { |invoice| invoice.invoice_amount_was != invoice.invoice_amount && invoice.use_credit_balance}
  after_update :auto_adjustment_payment_on_update_without_credit_balance , :if => Proc.new { |invoice| invoice.invoice_amount_was != invoice.invoice_amount}
  after_create :update_client_as_arrived_or_completed
  before_save :generate_invoice_number, :if => Proc.new { |invoice| invoice.new_record? }

  def auto_adjustment_payment
    patient = self.patient
    payments_having_credit_amount = patient.payments_having_credit_balance
    if patient.calculate_patient_credit_amount > 0 && payments_having_credit_amount.count > 0
      inv_amount = self.invoice_amount
      payments_having_credit_amount.each do |payment|
        if inv_amount > 0
          adjustable_amount = payment.get_paid_amount(false) - payment.deposited_amount_of_invoice_via_amount
          if inv_amount <= adjustable_amount
            InvoicesPayment.create(amount: inv_amount , payment_id: payment.id , invoice_id: self.id)
            inv_amount = 0
          else
            InvoicesPayment.create(amount: ( adjustable_amount)  , payment_id: payment.id , invoice_id: self.id)
            inv_amount = (inv_amount - adjustable_amount)
          end
        end
      end
    end
    pending_invoices_settlement(patient)
  end

  def pending_invoices_settlement(pat)
    patient = pat
    pending_invoices = patient.invoices.where('close_date IS NULL')
    payments_having_credit_amount = patient.payments_having_credit_balance
    if patient.calculate_patient_credit_amount > 0 && payments_having_credit_amount.count > 0
      pending_invoices.each do |inv|
        pay_amt = 0
        inv_pay = inv.invoices_payments
        if inv_pay.present?
          inv_pay.each do |pay|
            pay_amt = pay_amt + pay.amount
          end
        end
        inv_amount = (inv.invoice_amount - pay_amt)
        payments_having_credit_amount.each do |payment|
          if inv_amount > 0
            adjustable_amount = payment.get_paid_amount(false) - payment.deposited_amount_of_invoice_via_amount
            if inv_amount <= adjustable_amount
              InvoicesPayment.create(amount: inv_amount , payment_id: payment.id , invoice_id: inv.id)
              inv_amount = 0
            else
              InvoicesPayment.create(amount: ( adjustable_amount)  , payment_id: payment.id , invoice_id: inv.id)
              inv_amount = (inv_amount - adjustable_amount)
            end
          end
        end
      end
    end
  end

  def auto_adjustment_payment_on_update
    last_invoice_payments = self.invoices_payments
    last_invoice_payments_amount = last_invoice_payments.map(&:amount).compact.sum
    updated_invoice_amount = self.invoice_amount
    modified_amnt = updated_invoice_amount - last_invoice_payments_amount
    patient = self.patient
    if modified_amnt > 0
      payments_having_credit_amount = patient.payments_having_credit_balance
      if patient.calculate_patient_credit_amount > 0 && payments_having_credit_amount.count > 0
        inv_pay_ids = last_invoice_payments.map(&:payment_id)
        payments_having_credit_amount.each do |payment|
          adjustable_amount = payment.get_paid_amount(false) - payment.deposited_amount_of_invoice_via_amount
          if modified_amnt <= adjustable_amount
            if inv_pay_ids.include? payment.id
              inv_pay = InvoicesPayment.where('invoice_id = ? and payment_id = ? and status = ?', self.id, payment.id, true).last
              if inv_pay.present?
                inv_pay.update_column(:amount, (modified_amnt + inv_pay.amount))
              end
            else
              InvoicesPayment.create(amount: modified_amnt , payment_id: payment.id , invoice_id: self.id)
            end

            modified_amnt = 0
          else
            if inv_pay_ids.include? payment.id
              inv_pay = InvoicesPayment.where('invoice_id = ? and payment_id = ? and status = ?', self.id, payment.id, true).last
              if inv_pay.present?
                inv_pay.update_column(:amount, (adjustable_amount + inv_pay.amount))
              end
            else
              InvoicesPayment.create(amount: ( adjustable_amount)  , payment_id: payment.id , invoice_id: self.id)
            end
            modified_amnt = (modified_amnt - adjustable_amount)
          end
        end
      end
    else
      modified_amnt = modified_amnt.abs
      last_invoice_payments.each do |inv_pmt|
        if modified_amnt > 0
          adjustable_amnt = inv_pmt.amount
          if modified_amnt <= adjustable_amnt
            inv_pmt.update_column(:amount, (adjustable_amnt - modified_amnt))
            modified_amnt = 0
          else
            inv_pmt.update_column(:status, false)
            modified_amnt = (modified_amnt - adjustable_amnt)
          end
        end
      end
    end
  end


  def auto_adjustment_payment_on_update_without_credit_balance
    last_invoice_payments = self.invoices_payments
    last_invoice_payments_amount = last_invoice_payments.map(&:amount).compact.sum
    updated_invoice_amount = self.invoice_amount
    if last_invoice_payments_amount > updated_invoice_amount
      modified_amnt = updated_invoice_amount - last_invoice_payments_amount
      patient = self.patient
      modified_amnt = modified_amnt.abs
      last_invoice_payments.each do |inv_pmt|
        if modified_amnt > 0
          adjustable_amnt = inv_pmt.amount
          if modified_amnt <= adjustable_amnt
            inv_pmt.update_column(:amount, (adjustable_amnt - modified_amnt))
            modified_amnt = 0
          else
            inv_pmt.update_column(:status, false)
            modified_amnt = (modified_amnt - adjustable_amnt)
          end
        end
      end
    end
  end


  def update_client_as_arrived_or_completed
    appnt = nil
    appnt_inv = AppointmentsInvoice.find_by(invoice_id: self.id)
    appnt = appnt_inv.appointment if appnt_inv.present?
    if appnt.present?
      if self.close_date == nil
        appnt.update_column(:patient_arrive, 1)
      else
        appnt.update_column(:appnt_status, 1)
      end
    end
  end

  def generate_invoice_number
    last_invoice = self.patient.company.invoices.order('created_at DESC').first rescue nil
    invoice_setting = self.patient.company.invoice_setting
    if invoice_setting.present? && (invoice_setting.try(:starting_invoice_number) == invoice_setting.try(:next_invoice_number))
      new_invoice_number = invoice_setting.next_invoice_number - 1
      self.number = InvoiceNumber::Builder.new.create(new_invoice_number)
      invoice_setting.update_columns(:next_invoice_number => nil)
    elsif last_invoice.try(:number).present?
      self.number = InvoiceNumber::Builder.new.create(last_invoice.number)
    else
      self.number = InvoiceNumber::Builder.new.create
    end
  end

  # update product and its stock level
  def product_stock_adjustment
    self.invoice_items.each do |invoice_item|
      if invoice_item.item_type.to_s.eql?('Product')
        stock = invoice_item.item.product_stocks.find_or_create_by(:stock_level => false, :stock_type => 'Item Sold', :invoice => self, :product_id => invoice_item.item.id, :adjusted_by => $current_user.try(:id))
        if stock.new_record?
          stock.assign_attributes(:adjusted_at => DateTime.now.strftime('%e %b ,%Y,%l:%M%p'), :quantity => invoice_item.quantity)
          invoice_item.item.update_column('stock_number', invoice_item.item.stock_number - invoice_item.quantity)
        else
          new_product_stock_number = invoice_item.item.stock_number+ (stock.quantity - invoice_item.quantity)
          invoice_item.item.update_column('stock_number', new_product_stock_number)
          stock.assign_attributes(:adjusted_at => DateTime.now.strftime('%e %b ,%Y,%l:%M%p'), :quantity => invoice_item.quantity)
        end
        stock.save
      end
    end
  end

  # Quickbooks callback
  after_commit :sync_invoice_with_qbo, :on => [:create, :update], :if => Proc.new { |invoice| invoice.status && $qbo_credentials.present? }

  def sync_invoice_with_qbo
    invoice = Intuit::OpustimeInvoice.new(self.id, $token, $secret, $realm_id, $qbo_credentials.id)
    invoice.sync
  end

  # validate :check_for_valid_invoice_on_update

  # after_create :add_invoice_record_to_xero
  # after_update :update_invoice_record_to_xero


  def check_stocks_quantity
    if self.status_invoice? == true
      self.invoice_items.each do |inv_item|
        if inv_item.item.class.name.eql? "Product"
          product = inv_item.item
          if product.try(:stock_number).to_i > 0 && product.try(:stock_number).to_i >= inv_item.quantity
            product_stock_number = product.try(:stock_number).to_i - inv_item.quantity.to_i
            product.update_attributes(:stock_number => product_stock_number)
          else
            self.errors.add(:Quantity, " of invoice item is much bigger from stocks")
            return false
          end
        end
      end
    end
  end

  self.per_page = 30

  def status_invoice?

    return self.status
  end


  def check_status?
    return !status
  end

  def check_for_valid_invoice_on_update
    # Getting total paid money for an invoice
    paid_money_for_invoice = total_paid_money_for_invoice
    if invoice_amount.to_i < paid_money_for_invoice
      self.errors.add(:invoice_total, "is less than allocated payments, please reduce allocations first")
    end
  end

  def total_paid_money_for_invoice
    invoices_payments = InvoicesPayment.where(["invoice_id = ? AND status = ?", self.id, true]).select("amount")
    paid_money_for_invoice = invoices_payments.map(&:amount).compact.sum
    puts "----------------------------#{paid_money_for_invoice}"
    return paid_money_for_invoice
  end

  def deposited_amount_of_invoice
    puts"====deposited_amount_of_invoice==============="
    invoices_payments = self.invoices_payments.active_invoices_payments.select("amount , credit_amount")
    total_amount = invoices_payments.map(&:amount).compact.sum
    puts"==total_amount===#{total_amount.inspect}============"
    total_credit_amount = invoices_payments.map(&:credit_amount).compact.sum
    puts"===total_credit_amount===#{total_credit_amount.inspect}===="
    return total_amount + total_credit_amount
  end

  def calculate_outstanding_balance(p_id=nil)
    puts"===calculate_outstanding_balance---------------"
    if p_id.nil?
      puts"==if id nil?======"
      invoices_payments = self.invoices_payments.active_invoices_payments
      puts"===invoices_payments---#{invoices_payments.inspect}====="
    else
      puts"==---else-----------"
      invoices_payments = self.invoices_payments.active_invoices_payments.where(payment_id: p_id)
    puts"==---invoices_payments----#{invoices_payments.inspect}-----------"
    end

    outstanding_balance = self.invoice_amount.to_f - (invoices_payments.map(&:amount).compact.sum + invoices_payments.map(&:credit_amount).compact.sum)
    puts"====outstanding_balance===#{outstanding_balance.inspect}==============="
    return (outstanding_balance < 0 ? 0 : outstanding_balance)
  end

  def get_payment_detail
    payments = self.payments.active_payment
    result = []
    payments.each do |payment|
      item = {}
      payment_info = payment.get_invoice_wise_payment_detail(self)
      paid_amount = payment_info[:alloted_amount]
      unless paid_amount.to_f == 0
        item[:payment_id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s
        item[:payment_date] = payment.payment_date.strftime("%d %b %Y, %H:%M %p")
        item[:payment_datail] = payment_info
        result << item
      end

    end
    return result
  end

  def get_item_info
    str =""
    self.invoice_items.select("id , item_type , item_id").each do |invoice_item|
      if invoice_item.item_type.casecmp("BillableItem") == 0
        item = invoice_item.item_type.constantize.find(invoice_item.item_id) rescue nil
        unless item.nil?
          if item.item_type
            str += " SERVICE: " + item.try(:name) + ","
          else
            str += " OTHER: " + item.try(:name)+ ","
          end
        end
      else
        item_name = invoice_item.item_type.constantize.find(invoice_item.item_id).try(:name) rescue nil
        str += " " + invoice_item.item_type.upcase + ": " + item_name+ "," unless item_name.nil?
      end
    end
    return str[0, str.length - 1]

  end

  def rollback_amount_to_patient_credit_amount
    if self.status == false
      # patient = self.patient
      self.invoices_payments.each do |invoice_payment|
        invoice_payment.update_attributes(:status => false)
      end
    end
  end

  def changing_payment_assoicaite_after_removing_invoice
    self.invoices_payments.each do |inv_pay|
      inv_pay.update_columns(status: false)
      payment = inv_pay.payment
      payment.update_attributes(:status => false) unless payment.invoices_payments.map(&:status).uniq.include?true
    end
  end

  def get_items_info
    item_name= []
    invoice_items = self.invoice_items
    invoice_items.each do |invoice_item|
      if (invoice_item.item_type <=> "Product") == 0
        product = Product.find(invoice_item.item_id) rescue nil
        item_name << product.name + (product.item_code.nil? ? "" : "(#{product.item_code})") unless product.nil?
      elsif (invoice_item.item_type <=> "BillableItem") == 0
        billable_item = BillableItem.find(invoice_item.item_id) rescue nil
        item_name << billable_item.name unless billable_item.nil?
      end
    end
    return item_name
  end

  def formatted_id
    "0"*(6-self.id.to_s.length)+ self.id.to_s
  end

  def practitioner_name
    User.find(self.practitioner).full_name_with_title
  end

  def total_amount
    self.invoice_items.map(&:total_price).sum
  end

  def self.to_csv(options = {})
    column_names = ["DATE", "PRACTITIONER", "PAYMENT_TYPE", "PRODUCTS SERVICES", "BUSINESS", "TOTAL_PAYMENT"]
    CSV.generate(options) do |csv|
      csv << column_names
    end
  end

  # Xero functionality
  def add_invoice_record_to_xero
    begin
      company = self.patient.company
      xero_session = company.xero_session
      unless xero_session.nil?
        if xero_session.is_connected
          xero_gateway = XeroGateway::Gateway.new(CONFIG[:XERO_KEY], CONFIG[:XERO_SECRET])
          xero_gateway.authorize_from_access(xero_session.access_token, xero_session.access_secret)
          invoice_id = self.formatted_id
          invoice = xero_gateway.build_invoice({
                                                   :invoice_type => "ACCREC",
                                                   :due_date => 1.month.from_now,
                                                   :invoice_number => invoice_id,
                                                   :line_amount_types => "Inclusive",
                                                   :total => self.invoice_amount,
                                                   :invoice_status => "AUTHORISED"
                                               })
          invoice.contact.name = self.patient.full_name
          invoice.contact.phone.number = self.patient.patient_contacts.first.contact_no if self.patient.patient_contacts.length > 0
          invoice.contact.address.line_1 = self.patient.full_address

          self.invoice_items.each do |b_item|
            # Getting name of billable item
            if b_item.item_type.casecmp("BillableItem") == 0
              item = BillableItem.find(b_item.item_id)
            else
              item = Product.find(b_item.item_id)
            end
            tax_amount = (b_item.total_price.to_f - (b_item.unit_price.to_f * b_item.quantity))/b_item.quantity.to_f
            unit_amount = b_item.unit_price.to_f + tax_amount

            ac_code = get_xero_ac_for_item(item, xero_session)

            tax_code = get_xero_tax_for_item(item, xero_session)


            line_item = XeroGateway::LineItem.new(
                :description => item.try(:name),
                :account_code => ac_code.nil? ? "200" : ac_code,
                :unit_amount => unit_amount,
                :quantity => b_item.quantity,
                :tax_type => tax_code.nil? ? "NONE" : tax_code,
                :tax_amount => tax_amount

            # :item_code => "15" #item.try(:item_code)        
            )
            line_item.tracking << XeroGateway::TrackingCategory.new(:name => "tracking category", :options => "tracking option")
            invoice.line_items << line_item
          end
          invoice.create
        end
      end
    rescue Exception => e
      puts "Error - #{e.message}"
    end
  end

  def update_invoice_record_to_xero
    begin
      company = self.patient.company
      xero_session = company.xero_session

      unless xero_session.nil?
        if xero_session.is_connected
          xero_gateway = XeroGateway::Gateway.new(CONFIG[:XERO_KEY], CONFIG[:XERO_SECRET])
          xero_gateway.authorize_from_access(xero_session.access_token, xero_session.access_secret)

          invoice_res = xero_gateway.get_invoice(self.formatted_id)

          invoice = invoice_res.invoices.first
          invoice.due_date = 1.month.from_now
          invoice.line_amount_types = "Inclusive"

          invoice.line_items = []
          self.invoice_items.each do |b_item|
            # Getting name of billable item 
            if b_item.item_type.casecmp("BillableItem") == 0
              item = BillableItem.find(b_item.item_id)
            else
              item = Product.find(b_item.item_id)
            end

            tax_amount = (b_item.total_price.to_f - (b_item.unit_price.to_f * b_item.quantity))/b_item.quantity.to_f
            unit_amount = b_item.unit_price.to_f + tax_amount

            line_item = XeroGateway::LineItem.new(
                :description => item.try(:name),
                :account_code => xero_session.inv_item_code.nil? ? "200" : xero_session.inv_item_code.to_i,
                :unit_amount => unit_amount,
                :quantity => b_item.quantity,
                :tax_type => xero_session.tax_rate_code.nil? ? "NONE" : xero_session.tax_rate_code.to_s,
                :tax_amount => tax_amount

            )
            line_item.tracking << XeroGateway::TrackingCategory.new(:name => "tracking category", :options => "tracking option")
            invoice.line_items << line_item
          end
          invoice.save
        end
      end

    rescue Exception => e
      puts "Error - #{e.message}"
    end
  end

  def get_xero_ac_for_item(item, xero_model)
    xero_code = item.xero_code
    result = xero_code.nil? ? xero_model.inv_item_code : xero_code
    return result
  end

  def get_xero_tax_for_item(item, xero_session)
    tax_code = xero_session.payment_code

    tax = item.tax
    unless ["N/A", nil, ""].include? tax
      tax_setting_code = TaxSetting.find(tax).xero_tax
      unless tax_setting_code.nil?
        tax_code = tax_setting_code
      end
    end
    return tax_code
  end

  def next_invoice
    comp = self.patient.company
    invoice_ids = comp.invoices.active_invoice.order("invoices.created_at desc").ids
    ele_index = invoice_ids.index(self.id)
    next_elem = invoice_ids.at(ele_index + 1)
    return next_elem
  end

  def prev_invoice
    comp = self.patient.company
    invoice_ids = comp.invoices.active_invoice.order("invoices.created_at desc").ids
    ele_index = invoice_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : invoice_ids.at(prev))
    return prev_elem
  end


  def update_activity_log
    msg = {}
    changes = self.audits.last.audited_changes

    if changes.keys.include? "invoice_amount"
      msg[:old_amount] = changes["invoice_amount"].try(:first)
      msg[:new_amount] = changes["invoice_amount"].try(:second)
    else
      msg = nil
    end
    return msg
  end

end

    