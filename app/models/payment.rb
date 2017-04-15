class Payment < ActiveRecord::Base
  audited allow_mass_assignment: true
  has_associated_audits

  include PublicActivity::Model
  tracked owner: Proc.new { |controller, model| controller.current_user ? controller.current_user : nil },
          company: Proc.new { |controller, model| model.patient.company },
          business_id: Proc.new { |controller, model| model.business.try(:id) }

  belongs_to :patient

  belongs_to :creater, :polymorphic => true
  belongs_to :updater, :polymorphic => true
  has_many :payment_types_payments
  has_many :payment_types, :through => :payment_types_payments, dependent: :destroy
  accepts_nested_attributes_for :payment_types_payments

  has_many :invoices_payments
  has_many :invoices, :through => :invoices_payments, dependent: :destroy
  accepts_nested_attributes_for :invoices_payments

  has_one :businesses_payment, :dependent => :destroy, :inverse_of => :payment
  has_one :business, :through => :businesses_payment, :dependent => :destroy
  accepts_nested_attributes_for :businesses_payment, :reject_if => proc { |attributes| attributes['business_id'].nil? }, :allow_destroy => true
  validates_presence_of :businesses_payment

  # after_create :add_payment_to_xero

  # Quickbooks callback
  after_commit :sync_payment_with_qbo, :on => [:create, :update], :if => Proc.new { $qbo_credentials.present? && self.status }

  validate :blank_payment_not_allowed, :if => Proc.new { self.status }

  def sync_payment_with_qbo
    payment = Intuit::OpustimePayment.new(self.id, $token, $secret, $realm_id)
    payment.sync
  end

  def blank_payment_not_allowed
    self.errors.add(:Payment , ' amount cannot be zero') if self.payment_types_payments.empty? && self.invoices_payments.empty?
  end


  validates_presence_of :patient

  scope :active_payment, -> { where(status: true) }

  validates :patient, presence: true
  validates :businessid, presence: true
  self.per_page = 30

  # validates_associated :payment_types_payments , :message=> {"amount can not be zoro"}

  after_update :make_false_payment_associated_model, :if => :check_status?

  def make_false_payment_associated_model
    self.payment_types_payments.active_payment_types_payments.each do |payment_type|
      payment_type.update_attributes(:status => false)
    end

    self.invoices_payments.active_invoices_payments.each do |invoice_type|
      invoice_type.update_attributes(:status => false)
    end
  end

  def get_payment_sources
    p_sources = []
    self.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0]).each do |payment_type_payment|
      item = {}
      item[:id] = payment_type_payment.id
      item[:payment_type_id] = payment_type_payment.payment_type_id.to_s
      item[:name] = payment_type_payment.payment_type.try(:name)
      item[:amount] = payment_type_payment.amount
      p_sources << item
    end
    return p_sources

  end

  def get_source_name_with_amount
    str = ""
    self.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0]).each do |payment_type_payment|
      str += payment_type_payment.payment_type.try(:name).to_s + " $" + '%.2f'%(payment_type_payment.amount.to_s) + ","
    end
    return str[0, str.length - 1]
  end

  def get_paid_amount(flag = true)
    if flag
      self.payment_types_payments.active_payment_types_payments.map(&:amount).compact.sum.round(2)
    else
      self.payment_types_payments.active_payment_types_payments.map(&:amount).compact.sum
    end

  end

  def deposited_amount_of_invoice
    invoices_payments = self.invoices_payments.active_invoices_payments.select("amount , credit_amount")
    total_amount = invoices_payments.map(&:amount).compact.sum
    total_credit_amount = invoices_payments.map(&:credit_amount).compact.sum
    return total_amount + total_credit_amount
  end

  def deposited_amount_of_invoice_via_amount
    invoices_payments = self.invoices_payments.active_invoices_payments.select("amount , credit_amount")
    total_amount = invoices_payments.map(&:amount).compact.sum
    return total_amount
  end

  def get_list_invoices(patient)
#   Getting those invoices for which some amount has been deposited    
    previous_paid_payment_for_invoices = self.invoices_payments #InvoicesPayment.where(:payment_id => self.id)
    result = {}
    previous_invoices_ids = []
    invoice_result = []
    previous_paid_payment_for_invoices.each do |invoice_payment|
      invoice = invoice_payment.invoice
      item = {}
      item[:id] = invoice_payment.id
      item[:invoice_id] = id_format(invoice)
      previous_invoices_ids << invoice.id
      item[:issue_date] = invoice.issue_date
      item[:practitioner] = practitioner_name(invoice.practitioner)
      item[:invoice_total] = invoice.invoice_amount
      item[:amount_outstanding] = invoice.deposited_amount_of_invoice == 0 ? invoice.outstanding_balance : (invoice.outstanding_balance + invoice.deposited_amount_of_invoice)
      item[:amount] = invoice.deposited_amount_of_invoice
      item[:amount_remaining] = item[:amount_outstanding].to_f - item[:amount].to_f
      invoice_result << item
    end

#   Getting all new invoices for this patient  
    new_invoices = patient.invoices.dues.where("invoices.id NOT IN (?)", previous_invoices_ids).select("id , issue_date , invoice_amount ,outstanding_balance, practitioner")
    new_invoices.each do |invoice|
      item = {}
      item[:invoice_id] = id_format(invoice)
      item[:issue_date] = invoice.issue_date
      item[:practitioner] = practitioner_name(invoice.practitioner)
      item[:invoice_total] = invoice.invoice_amount
      item[:amount_outstanding] = invoice.outstanding_balance # invoice.deposited_amount_of_invoice == 0 ? invoice.outstanding_balance : (invoice.outstanding_balance + invoice.deposited_amount_of_invoice)
      item[:amount] = invoice.deposited_amount_of_invoice
      item[:amount_remaining] = item[:amount_outstanding].to_f - item[:amount].to_f
      invoice_result << item
    end
    return invoice_result
  end

  #   Methods for show page 
  def get_paid_payments_and_total
    payment_sources = self.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0])
    payment_history = {}
    payment_history[:paid_payment_amount_list] = []
    payment_sources.each do |source|
      item = {}
      item[:payment_type_name] = source.payment_type.try(:name)
      item[:paid_money] = source.amount.round(2)
      payment_history[:paid_payment_amount_list] << item
    end
    payment_history[:total_amount] = payment_sources.map(&:amount).compact.sum.round(2)
    return payment_history
  end

  def get_invoices_list_applied_payment
    payment_invoices = self.invoices_payments.active_invoices_payments.where(["invoices_payments.amount  > ? || invoices_payments.credit_amount > ? ", 0, 0]) #InvoicesPayment.where(payment_id: self.id)
    invoices_history = {}
    invoices_history[:invoice_listing] = []
    payment_invoices.each do |inv_payment|
      item = {}
      item[:invoice_id] = id_format(inv_payment.invoice)
      item[:invoice_number] = inv_payment.invoice.try(:number)
      item[:applied_amount] = '% .2f'% (inv_payment.amount.to_f + inv_payment.credit_amount.to_f)
      item[:invoice_status] = inv_payment.status
      invoices_history[:invoice_listing] << item
    end
    return invoices_history
  end

  def calculate_credit_amount
    inv_payments = self.invoices_payments.active_invoices_payments
    total_credit_amount = self.payment_types_payments.active_payment_types_payments.map(&:amount).compact.sum - (inv_payments.map(&:amount).compact.sum + inv_payments.map(&:credit_amount).compact.sum)
    # total_credit_amount = self.payment_types_payments.active_payment_types_payments.map(&:amount).compact.sum - (inv_payments.map(&:amount).compact.sum + inv_payments.map(&:credit_amount).compact.sum)  + (self.invoices_payments.where(["invoices_payments.status = ? ", false]).map(&:amount).compact.sum + self.invoices_payments.where(["invoices_payments.status = ? ", false]).map(&:credit_amount).compact.sum)
    return total_credit_amount
  end

  def get_invoice_wise_payment_detail(invoice)
    result = {}
    payment_invoice = self.invoices_payments.active_invoices_payments.where(invoice_id: invoice.id).first
    paid_amount = payment_invoice.amount.to_f + payment_invoice.credit_amount.to_f
    unless paid_amount == 0
      payment_types_payments = self.payment_types_payments.active_payment_types_payments
      result[:payment_modes] = []
      payment_types_payments.each do |payment_mode|
        item = {}
        item[:name] = payment_mode.payment_type.try(:name)
        item[:amount] = '% .2f'% (payment_mode.amount.to_f)
        result[:payment_modes] << item
      end
      result[:alloted_amount] = '% .2f'% (paid_amount)
    end
    return result
  end

  def payment_ways
    names = []
    self.payment_types_payments.each do |payment_type_payment|
      names << payment_type_payment.payment_type.name unless payment_type_payment.payment_type.nil?
    end
    return names
  end

  def add_payment_to_xero
    begin
      company = self.patient.company
      xero_session = company.xero_session
      unless xero_session.nil?
        if xero_session.is_connected
          xero_gateway = XeroGateway::Gateway.new(CONFIG[:XERO_KEY], CONFIG[:XERO_SECRET])
          xero_gateway.authorize_from_access(xero_session.access_token, xero_session.access_secret)
          related_invoices = self.invoices
          invoices_id = []
          related_invoices.each do |inv|
            invoice_arr = xero_gateway.get_invoice(inv.formatted_id) rescue nil
            unless invoice_arr.nil?
              # which payment account is connected 
              payment_account = xero_payment_account(xero_gateway, xero_session)

              if invoice_arr.try(:invoices).length > 0

                invoice = invoice_arr.try(:invoices).try(:first)
                # making a payment in xero a/c
                payment = XeroGateway::Payment.new(
                    :amount => inv.total_paid_money_for_invoice - invoice.amount_due.to_f > 0 ? invoice.amount_due.to_f : inv.total_paid_money_for_invoice,
                    :date => self.payment_date,
                    :reference => "Payment ##{id_format(self)}",
                    :invoice_id => invoice.invoice_id,
                    :code => payment_account.code,
                    :account_id => payment_account.account_id
                )
                xero_gateway.create_payment(payment)
              end
            end
          end
        end
      end
    rescue Exception => e
      puts "Error - #{e.message}"
    end
  end

  def all_practitioners_names_for_all_involved_invoices
    names = []
    invoices = self.invoices.active_invoice

    invoices.each do |inv|
      names << inv.user.try(:full_name_with_title)
    end
    return names
  end

  def used_products
    names = []
    invoices = self.invoices.active_invoice
    invoices.each do |inv|
      prods = inv.invoice_items.where(["item_type = ?", "Product"]).select("id , item_id , item_type ")
      prods.each do |prod|
        names << prod.item.try(:name)
      end
    end
    return names
  end

  def used_services
    names = []
    invoices = self.invoices.active_invoice
    invoices.each do |inv|
      prods = inv.invoice_items.where(["item_type = ?", "BillableItem"]).select("id , item_id , item_type ")
      prods.each do |prod|
        names << prod.item.try(:name)
      end
    end
    return names
  end

  def self.to_csv(options = {}, flag = true)
    if flag == true
      column_names = ["DATE", "PRACTITIONER", "PAYMENT_TYPE", "PRODUCTS", "SERVICES", "BUSINESS", "TOTAL_PAYMENT"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |payment|
          data = []
          data << payment.payment_date.strftime("%A%d%b%Yat%H:%M%p")
          data << payment.all_practitioners_names_for_all_involved_invoices.map { |k| k.gsub(" ", "") }.join("_")
          data << payment.payment_types.map(&:name).map { |k| k.gsub(" ", "") }.join("_")
          data << payment.used_products.map { |k| k.gsub(" ", "") }.join("_")
          data << payment.used_services.map { |k| k.gsub(" ", "") }.join("_")
          data << payment.business.try(:name).gsub(" ", "")
          data << payment.get_paid_amount
          csv << data
        end
      end
    else
      column_names = ["PAYMENT", "DATE/TIME", "PATIENT", "SOURCE(S)", "TOTAL"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |payment|
          data = []
          data << "0"*(6-payment.id.to_s.length)+ payment.id.to_s
          data << payment.payment_date.strftime("%d %b %Y , %H:%M%p").gsub(" ", "")
          data << payment.patient.full_name
          source_names = []
          payment.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0]).each do |obj|
            p_name = obj.payment_type.try(:name)
            p_name = p_name.to_s + ':' + obj.amount.to_s
            source_names << p_name
          end
          data << source_names.join(",")
          data << payment.get_paid_amount
          csv << data
        end
      end
    end

  end

  def next_payment
    comp = self.patient.company
    payment_ids = comp.payments.active_payment.order("payments.created_at desc").ids
    ele_index = payment_ids.index(self.id)
    next_elem = payment_ids.at(ele_index + 1)
    return next_elem


  end

  def prev_payment
    comp = self.patient.company
    payment_ids = comp.payments.active_payment.order("payments.created_at desc").ids
    ele_index = payment_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : payment_ids.at(prev))
    return prev_elem

  end

  def attached_invoices_ids
    ids = []
    invoices = self.invoices.active_invoice
    invoices.each do |inv|
      ids << ("0"*(6-inv.id.to_s.length)+ inv.id.to_s)
    end
    result = []
    if ids.length > 0
      ids.each do |id|
        item = {}
        item[:inv_id] = id
        result << item
      end
      return result
    else
      return "None"
    end
  end

  def create_activity_logs(current_person)
    "#{self.created_at.strftime("%H:%M%p")}, <b>#{current_person.full_name}</b> - <span>created payment</span> <b>#{"0"*(6-self.id.to_s.length)+ self.id.to_s}</b> of <b>$#{self.deposited_amount_of_invoice}</b> <b>#{self.payment_ways}</b> for invoice <b>#{self.attached_invoices_ids}</b> for <b>#{self.patient.full_name}</b>"
  end

  def update_activity_logs(old_amount)
    msg = {}
    new_amount = self.deposited_amount_of_invoice

    if old_amount != new_amount
      msg[:old_amount] = old_amount
      msg[:new_amount] = new_amount
    else
      msg = nil
    end
    return msg
  end

  def formatted_id
    "0"*(6-self.id.to_s.length)+ self.id.to_s
  end

  def pay_type
    ptype = PaymentTypesPayment.find_by(payment_id: self.id)
    type = PaymentType.find_by(id: ptype.payment_type_id) if ptype.present?
    type.try(:name)
  end


  private

  def id_format(obj)
    formatted_id = "0"*(6-obj.id.to_s.length)+ obj.id.to_s
    return formatted_id
  end

  def practitioner_name(id)
    practitioner = User.find(id)
    full_name = practitioner.first_name + " " + practitioner.last_name
    return full_name
  end

  def check_status?
    return !status
  end

  def xero_payment_account(xero_gateway, xero_session)
    account_list = xero_gateway.get_accounts_list
    payment_account = account_list.find_by_code(xero_session.payment_code.nil? ? "880" : xero_session.payment_code)
    return payment_account
  end



end
