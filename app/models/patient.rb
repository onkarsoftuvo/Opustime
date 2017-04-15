class Patient < ActiveRecord::Base
  include IdentificationKey

  belongs_to :company

  serialize :relationship, Array
  # serialize :phone_list , Array
  # serialize :medical_alert , Array
  serialize :referrer, JSON
  serialize :refer_doctor, JSON

  has_many :invoices, :dependent => :destroy
  has_many :payments, :dependent => :destroy
  belongs_to :referral, :polymorphic => true
  has_many :patients, :as => :referral, :dependent => :destroy

  # for Quickbooks logs
  has_many :logs, :as => :loggable, :dependent => :destroy, :class_name => 'QboLog'

  has_many :patient_contacts, :dependent => :destroy
  has_many :medical_alerts, :dependent => :destroy
  accepts_nested_attributes_for :patient_contacts, :allow_destroy => true

  has_one :wait_lists_patient, :dependent => :destroy
  has_one :wait_list, :through => :wait_lists_patient, :dependent => :destroy

  has_many :treatment_notes, :dependent => :destroy
  has_many :communications, :dependent => :destroy
  has_many :recalls, :dependent => :destroy
  has_many :letters, :dependent => :destroy
  has_many :file_attachments, :dependent => :destroy

  has_many :appointments, :dependent => :destroy
  has_many :users, -> { where("is_doctor= ? AND acc_active=?", true, true) }, :through => :appointments, :dependent => :destroy

  #Editing associations in patient module of concession and patient.
  has_one :concessions_patient, :dependent => :destroy
  has_one :concession, :through => :concessions_patient, :dependent => :destroy
  accepts_nested_attributes_for :concessions_patient, :allow_destroy => true

  has_one :patients_contact, :dependent => :destroy
  has_one :contact, :through => :patients_contact, :dependent => :destroy
  accepts_nested_attributes_for :patients_contact, :allow_destroy => true

  # has_many :sms_logs , :dependent => :destroy
  has_many :sms_logs, :as => :object, :dependent => :destroy

  # VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, :invoice_email, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i}, :on => [:create, :update], :allow_nil => true, :allow_blank => true
  validates :emergency_contact, :numericality => {:only_integer => true}, :allow_nil => true, :allow_blank => true

  # validates :postal_code, zipcode: {country_code_attribute: :country}, :allow_nil => true
  # validates :postal_code, zipcode: {country_code_attribute: :country}, :allow_blank => true

  validates_presence_of :first_name, :last_name
  validates :occupation, format: { with: /\A[a-zA-Z]+\z/, message: "Invalid Format only allows letters"}, :allow_blank => true
  # has_attached_file :profile_pic,
  #                   :url => "attachments/company/:company_id/patients/:id/:extension/:basename.:extension",
  #                   :path => "public/attachments/companies/:company_id/patients/:id/:extension/:basename.:extension"
  # validates_attachment_content_type :profile_pic, content_type: /\Aimage\/.*\Z/

  has_attached_file :profile_pic, styles: {
                               thumb: '100x100>',
                               medium: '300x300>'},
                               default_url: "/assets/missing.png"
                           

  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment_content_type :profile_pic, :content_type => /\Aimage\/.*\Z/
  do_not_validate_attachment_file_type :profile_pic

  Paperclip.interpolates :company_id do |attachment, style|
    attachment.instance.company_id
  end

  scope :active_patient, -> { where(["patients.status IN ('active' , 'archive')"]) }
  scope :specific_attributes, -> { select("id, title , first_name , last_name , gender, relationship , email, reminder_type, sms_marketing , address , country , state , city , postal_code , concession_type , invoice_to, invoice_email, invoice_extra_info, occupation, emergency_contact, medicare_number, reference_number, refer_doctor, notes, referral_type, referrer, extra_info, age , dob , status , updated_at , profile_pic ") }
  scope :specific_attributes_for_index, -> { select("id, title , first_name , last_name , dob, email , status ") }

  before_create :set_age
  before_update :set_age

  after_create :subscribe_to_mailchimp
  after_update :subscribe_to_mailchimp

  # Quickbooks callback
  after_save :sync_patient_with_qbo, :if => Proc.new { $qbo_credentials.present? }

  def sync_patient_with_qbo
    patient = Intuit::OpustimePatient.new(self.id, $token, $secret, $realm_id)
    patient.sync
  end

  before_save do |patient|
    # patient.invoice_to = patient.default_invoice_to if (patient.invoice_to.blank? || patient.invoice_to.nil?)
    if(patient.invoice_to.blank? || patient.invoice_to.nil?)
    patient.invoice_to = patient.default_invoice_to
    else
     patient.invoice_to = patient.default_invoice_to
  end
  end

  self.per_page = 30

  def calculate_patient_outstanding_balance(start_date=nil, end_date= nil)
    invoices = []
    if start_date.nil? && end_date.nil?
      invoices = self.invoices.active_invoice
    elsif start_date.nil? && !end_date.nil?
      invoices = self.invoices.active_invoice.where(["DATE(invoices.issue_date) <= ?  ", end_date.to_date])
    elsif !start_date.nil? && end_date.nil?
      invoices = self.invoices.active_invoice.where(["DATE(invoices.issue_date) >= ?  ", start_date.to_date])
    elsif !start_date.nil? && !end_date.nil?
      invoices = self.invoices.active_invoice.where(["DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? ", start_date.to_date, end_date.to_date])
    end

    patient_balance = 0
    invoices.each do |invoice|
      patient_balance += invoice.calculate_outstanding_balance
    end
    return  (patient_balance)
  end

  def calculate_patient_credit_amount
    payments = self.payments.active_payment
    patient_credit_amount = 0
    payments.each do |payment|
      patient_credit_amount += payment.calculate_credit_amount.to_f
    end
    return patient_credit_amount
  end

  def total_paid_amount
    invoices = self.invoices.active_invoice
    amount = 0.0
    invoices.each do |invoice|
      amount = amount + invoice.total_paid_money_for_invoice
    end
    return amount
  end

  def payments_having_credit_balance
      patient_credit_amount = self.calculate_patient_credit_amount
      payments = self.payments.active_payment.order('created_at desc')
      payment_ids = []
      amount = 0
      payments.each do |payment|
        if (payment.get_paid_amount > payment.deposited_amount_of_invoice_via_amount) && patient_credit_amount > 0
          amount = amount + (payment.get_paid_amount - payment.deposited_amount_of_invoice_via_amount)
          payment_ids << payment.id
          break if (amount > patient_credit_amount)
        end
      end
      return Payment.where(['id IN (?)' ,payment_ids ]).order('created_at  desc')
  end

  def full_name
    self.title.to_s.capitalize + ((self.title.to_s.casecmp('master') == 0 || self.title.to_s.blank?) ? ' ':'. ') + (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
  end

  def name_for_ical
    account = self.company.try(:account)
    unless account.nil?
      if account.patient_name_by.eql?('Full Name')
        return self.full_name
      elsif account.patient_name_by.eql?('First Name')
        return self.first_name.to_s
      elsif account.patient_name_by.eql?('Initials')
        return self.full_name_without_title
      end
    end
  end


  def full_name_without_title
    (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
  end

  def default_invoice_to
    country_name = ""
    state_name = ""
    unless self.country.nil?
      country = ISO3166::Country.new(self.country)
      country_name = country.try(:name)
      unless self.state.nil?
        state_code = self.try(:state).split("-")[1]
        state_name = country.states[state_code]["name"] unless state_code.nil?
      end
    end
    invoice_to = self.full_name
    unless self.address.to_s.blank?
      unless self.city.to_s.blank?
        invoice_to = invoice_to + ',' + self.address.to_s + ' ' + self.city.to_s + ''
        # invoice_to = invoice_to
      else
        invoice_to = invoice_to + ',' + self.address.to_s + ' '
        # invoice_to = invoice_to
      end
    end
    unless state_name.to_s.blank?
      invoice_to = invoice_to + ',' + state_name.to_s + ' '
      # invoice_to = invoice_to
    end
    unless country_name.to_s.blank?
      invoice_to = invoice_to +  ',' + country_name.to_s + ' '
      # invoice_to = invoice_to
    end
    unless postal_code.to_s.blank?
      invoice_to = invoice_to +',' + self.postal_code.to_s
      # invoice_to = invoice_to
    end
    return invoice_to
  end

  def get_state_country_name
    unless self.country.nil?
      country = ISO3166::Country.new(self.country)
      country_name = country.try(:name)
      unless self.state.nil?
        state_code = self.try(:state).split("-")[1]
        state_name = country.states[state_code]["name"] unless state_code.nil?
        return state_name , country_name
      else
        return '' , country_name
      end
    else
      return '' , ''
    end

  end

  def get_invoices(start_date=nil, end_date=nil, outstanding_invoice = false)
    invoices_list = []
    enate_item = BillableItem.find_by(enate_id: 'E-nate Ajustment', company_id: self.company_id)
    if start_date.nil? && end_date.nil?
      invoices_list = self.invoices.active_invoice.select("invoices.id ,invoices.number ,invoices.issue_date , invoices.practitioner , invoices.tax , invoices.invoice_amount , invoices.total_discount, invoices.businessid")
    elsif start_date.nil? && !end_date.nil?
      invoices_list = self.invoices.active_invoice.where(["DATE(invoices.issue_date) <= ?  ", end_date.to_date]).select("invoices.id , invoices.issue_date ,invoices.number, invoices.practitioner , invoices.tax , invoices.invoice_amount , invoices.total_discount, invoices.businessid")
    elsif !start_date.nil? && end_date.nil?
      invoices_list = self.invoices.active_invoice.where(["DATE(invoices.issue_date) >= ?  ", start_date.to_date]).select("invoices.id , invoices.issue_date , invoices.number,invoices.practitioner , invoices.tax , invoices.invoice_amount, invoices.total_discount, invoices.businessid")
    elsif !start_date.nil? && !end_date.nil?
      invoices_list = self.invoices.active_invoice.where(["DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? ", start_date.to_date, end_date.to_date]).select("invoices.id , invoices.issue_date , invoices.practitioner , invoices.number,invoices.tax , invoices.invoice_amount , invoices.total_discount, invoices.businessid")
    end
    result = []
    # raise invoices_list.first.inspect

    invoices_list.each do |invoice|
      # inv_enate_item = nil
      # inv_enate_item = invoice.invoice_items.where.not(item_id: enate_item.id) if enate_item.present?
      # if inv_enate_item == nil
        practi_info = invoice.user.practi_info.practi_refers.where('business_id = ?', invoice.businesses_invoice.try(:business_id)).first
        if outstanding_invoice
          unless invoice.calculate_outstanding_balance == 0
            item = {}
            item[:invoice_id] = invoice.id #"0"*(6-invoice.id.to_s.length)+ invoice.id.to_s
            item[:invoice_date] = invoice.issue_date.strftime("%m/%d/%Y")
            item[:practitoner] = invoice.user.try(:full_name_with_title)
            item[:practi_type] = practi_info.ref_type.present? ? practi_info.ref_type : 'NA'
            item[:practi_number] = practi_info.number.present? ? practi_info.number : 'NA'
            item[:invoice_items] = invoice.get_items_info.join(',')
            item[:invoice_amount] = '%.2f' % (invoice.invoice_amount)
            item[:tax] = invoice.tax.present? ? '%.2f'%(invoice.tax) : '0.00'
            item[:payment] = '%.2f' %(invoioce.total_paid_money_for_invoice)
            item[:invoice_outstanding] = '%.2f' % 0
            result << item
          end
        else
          item = {}
          item[:invoice_id] = invoice.id #"0"*(6-invoice.id.to_s.length)+ invoice.id.to_s
          item[:invoice_date] = invoice.issue_date.strftime("%m/%d/%Y")
          item[:practitoner] = invoice.user.try(:full_name_with_title)
          item[:practi_type] = practi_info.try(:ref_type).present? ? practi_info.try(:ref_type) : 'NA'
          item[:practi_number] = practi_info.try(:number).present? ? practi_info.try(:number) : 'NA'
          item[:invoice_items] = invoice.get_items_info.join(',')
          item[:invoice_amount] = '%.2f' % (invoice.invoice_amount)
          item[:tax] = '%.2f' %(invoice.tax)
          item[:payment] = '%.2f' %(invoice.total_paid_money_for_invoice)
          item[:invoice_outstanding] = '%.2f' % 0
          result << item
        end
      # else
      #   item = {}
      #   item[:invoice_id] = invoice.number #"0"*(6-invoice.id.to_s.length)+ invoice.id.to_s
      #   item[:invoice_date] = invoice.issue_date.strftime("%m/%d/%Y")
      #   item[:practitoner] = invoice.user.full_name_with_title_and_info(invoice.business.id)
      #   item[:invoice_items] = invoice.get_items_info.join(',')
      #   item[:invoice_amount] = '%.2f'%(invoice.invoice_amount)
      #   item[:tax] = '%.2f'%(invoice.tax)
      #   item[:payment] = '%.2f'%(invoice.total_paid_money_for_invoice)
      #   item[:invoice_outstanding] = '%.2f'%(invoice.calculate_outstanding_balance)
      #   result << item
      # end

    end
    return result
  end

  def get_payments(start_date=nil, end_date=nil)
    payments_list = []
    if start_date.nil? && end_date.nil?
      payments_list = self.payments.active_payment.select("payments.id , payments.payment_date")
    elsif start_date.nil? && !end_date.nil?
      payments_list = self.payments.active_payment.where(["DATE(payments.payment_date) <= ?  ", end_date.to_date]).select("payments.id , payments.payment_date")
    elsif !start_date.nil? && end_date.nil?
      payments_list = self.payments.active_payment.where(["DATE(payments.payment_date) >= ?  ", start_date.to_date]).select("payments.id , payments.payment_date")
    elsif !start_date.nil? && !end_date.nil?
      payments_list = self.payments.active_payment.where(["DATE(payments.payment_date) >= ? AND DATE(payments.payment_date) <= ? ", start_date.to_date, end_date.to_date]).select("payments.id , payments.payment_date")
    end
    result = []
    payments_list.each do |payment|
      item = {}
      item[:payment_id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s
      item[:payment_date] = payment.payment_date.strftime("%m/%d/%Y")
      item[:source] = payment.get_source_name_with_amount
      item[:total_paid] = '%.2f'%(payment.deposited_amount_of_invoice)
      item[:used_invoices] = payment.invoices.where('invoices.status = ?',1).map(&:id).join(',')
      result << item
    end
    return result
  end

  def get_business_detail_info(result, business)
    result[:business_name] = business.name
    result[:address] = business.address
    result[:city] = business.city
    country = business.country.nil? ? nil : ISO3166::Country.new(business.country)
    unless business.state.nil?
      unless country.nil?
        result[:state] = country.states[business.state.split("-")[1]]["name"]
      else
        result[:state] = nil
      end
    else
      result[:state] = nil
    end
    result[:pin_code] = business.pin_code
    result[:country] = business.country.nil? ? nil : country.try(:name)
    #result[:date] = business.updated_at.strftime("%d %b %Y")
    result[:date] = DateTime.now.strftime("%d %b %Y")
  end

  def get_referral_source
    self.referral_type.to_s #+ " " + (self.referrer.nil? ? "" : (self.referrer[:first_name].to_s + " " + self.referrer[:last_name].to_s)) + "-" +  self.extra_info.to_s  
  end

  def full_address
    patient_address = self.address
    patient_city = self.city
    country = self.country.nil? ? nil : ISO3166::Country.new(self.country)
    unless self.state.nil?
      unless country.nil?
        state = country.states[self.state.split("-")[1]]["name"] if state
      else
        state = nil
      end
    else
      state = nil
    end
    pin_code = self.postal_code
    country = self.country.nil? ? nil : country.try(:name)
    fulladdr = ((patient_address.to_s + ", ") unless patient_address.to_s.blank?).to_s +
        ((patient_city.to_s + ", ") unless patient_city.to_s.blank?).to_s +
        ((state.to_s + ", ") unless state.to_s.blank?).to_s +
        country.to_s +
        (("-" + pin_code.to_s) unless pin_code.to_s.blank?).to_s

    return fulladdr
  end

  def next_appointment
    today_date = Date.today
    time_now = Time.now.strftime("%H:%M:%S%p")
    appointment_next = self.appointments.active_appointment.order("DATE(appnt_date), appnt_time_start asc").where(["(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time)) OR Date(appnt_date) > ? ", today_date, time_now, today_date]).first

    return appointment_next
  end

  def subscribe_to_mailchimp
    company = self.company
    mail_chimp_info = company.mail_chimp_info
    unless mail_chimp_info.nil? || mail_chimp_info.list_id.nil?
      mailchimp = Mailchimp::API.new(mail_chimp_info.key) rescue nil
      subs_patient = []
      item = {}
      item[:EMAIL] = {"email" => self.email}
      item[:EMAIL_TYPE] = "html"
      merge_item = {}
      merge_item[:FNAME] = self.first_name
      merge_item[:LNAME] = self.last_name
      merge_item[:TITLE] = self.title
      merge_item[:GENDER] = self.gender
      merge_item[:DOB] = self.dob
      merge_item[:POSTAL_CODE] = self.postal_code
      merge_item[:LAST_APPOINTMENT_DATE] = self.appointments.order("created_at desc ").first.appnt_date.strftime("%Y-%m-%d") rescue nil
      merge_item[:LAST_BUSINESS_VISITED] = self.appointments.order("created_at desc ").first.business.try(:name) rescue nil
      merge_item[:LAST_PRACTITIONER_SEEN] = self.appointments.order("created_at desc ").first.user.try(:full_name_with_title) rescue nil
      item["merge_vars"] = merge_item

      subs_patient << item
      listId = mail_chimp_info.list_id
      mailchimp_status = mailchimp.lists.batch_subscribe(listId, subs_patient, false, true, false)
    end
    return mailchimp_status
  end

  def self.to_csv(options = {}, start_date = nil, end_date = nil, flag = true)
    if flag == true
      start_date = start_date.to_date unless start_date.nil?
      end_date = end_date.to_date unless end_date.nil?

      column_names = ["NAME", "EMAIL", "PHONE",
                      "ADDRESS", "PAID_AMOUNT", "OUTSTANDING_AMOUNT"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |patient|
          data = []
          data << patient.full_name.nil? ? 'N/A':patient.full_name
          data << patient.email.nil? ? 'N/A':patient.email
          data << (patient.patient_contacts.first.try(:contact_no).nil? ? 'N/A': patient.patient_contacts.first.try(:contact_no).phony_formatted(format: :international, spaces: '-'))
          data << patient.full_address.nil? ? 'N/A':patient.full_address
          data << patient.total_paid_amount
          data << patient.calculate_patient_outstanding_balance(start_date, end_date)
          csv << data # Adding appointment record in csv file
        end
      end
    elsif flag == false
      column_names = ["DAY", "NAME", "EMAIL", "PHONE", "ADDRESS"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |patient|
          data = []
          data << patient.dob.strftime("%dth %B")
          data << patient.full_name.nil? ? 'N/A' : patient.full_name
          data << patient.email.nil? ? 'N/A' : patient.email
          data << (patient.patient_contacts.first.try(:contact_no).nil? ? 'N/A': patient.patient_contacts.first.try(:contact_no).phony_formatted(format: :international, spaces: '-'))
          data << patient.full_address
          csv << data # Adding appointment record in csv file
        end
      end
    elsif flag == "none"
      column_names = ["DATE OF BIRTH", "NAME", "EMAIL", "PHONE",
                      "ADRESS", "OCCUPATION"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |patient|
          data = []
          data << (patient.dob.nil? ? patient.dob : patient.dob.strftime("%A , %d %B %Y"))
          data << patient.full_name.nil? ? 'N/A' : patient.full_name
          data << patient.email.nil? ? 'N/A' : patient.email
          data << (patient.patient_contacts.first.try(:contact_no).nil? ? 'N/A': patient.patient_contacts.first.try(:contact_no).phony_formatted(format: :international, spaces: '-'))
          data << patient.full_address.nil? ? 'N/A' : patient.full_address
          data << patient.occupation.nil? ? 'N/A' : patient.occupation

          csv << data # Adding appointment record in csv file
        end
      end
    elsif flag == "refer"
      column_names = ["DATE", "PATIENT NAME", "PHONE",
                      "SOURCE TYPE", "SOURCE NAME", "EXTRA INFO"]
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |patient|
          data = []
          data << patient.created_at.strftime("%d %b %Y , %H:%M%p")
          data << patient.full_name.nil? ? 'N/A' : patient.full_name
          data << (patient.patient_contacts.first.try(:contact_no).nil? ? 'N/A': patient.patient_contacts.first.try(:contact_no).phony_formatted(format: :international, spaces: '-'))
          data << patient.referral_type_subcategory
          data << patient.referral_type.nil? ? 'N/A' : patient.referral_type
          data << patient.extra_info.nil? ? 'N/A' : patient.extra_info

          csv << data # Adding appointment record in csv file
        end
      end
    end
  end

  def get_appointments_loc_and_doctor_wise(loc_id, doctor_id)
    self.appointments.joins(:user, :business).where(["users.id = ? AND businesses.id = ?", doctor_id, loc_id]).uniq

  end

  def get_mobile_no_type_wise(m_type)
    contact = self.patient_contacts.where(["patient_contacts.contact_type = ? ", m_type])

    cont_no = (contact.length > 0 ? contact.first.try(:contact_no).phony_formatted(format: :international, spaces: '-') : " ")
  end

  def get_contacts(index)
    contact = self.patient_contacts[index]
    contact_no = contact.try(:contact_no).phony_formatted(format: :international, spaces: '-') rescue nil
    return contact_no
  end

  def referral_type_subcategory
    result = " "
    if self.referral_type == "Patient"
      patient_id = self.referral.try(:id)
      unless patient_id.nil?
        patient = Patient.find_by_id(patient_id)
        result = patient.full_name unless patient.nil?
      end
    elsif self.referral_type == "Contact"
      unless self.referrer.nil?
        contact_id = self.referral.try(:id)
        unless contact_id.nil?
          contact = Contact.find_by_id(contact_id)
          result = contact.full_name unless contact.nil?
        end
      end
    elsif self.referral_type == "Other"
      result = " "
    else
      refer_id = self.referrer
      unless refer_id.nil?
        refer_sub = ReferralTypeSubcat.find_by_id(refer_id)
        result = refer_sub.try(:sub_name).to_s
      end
    end
    return result
  end

  def last_appointment
    self.appointments.active_appointment.last
  end

  def last_practitioner
    appnt = self.appointments.active_appointment
    if appnt.length > 0
      user = appnt.last.user
      doctor_name = user.full_name_with_title
    else
      doctor_name = " "
    end
    return doctor_name
  end

  def recalled?
    flag = false
    self.appointments.each do |appnt|
      if appnt.has_series
        flag = true
        break
      end
    end
    return flag
  end

  # method to get all appointments before on a date , For summary purpose
  def has_appointments_before(apnt)
    appnt = self.appointments.where(["(Date(appnt_date) < ?  AND status= ?) || (Date(appnt_date) <= ? AND appnt_time_start  < CAST(?  AS time) AND status= ?)", apnt.appnt_date, true, apnt.appnt_date, apnt.appnt_time_start, true]).uniq
    if appnt.length <= 0
      return false
    else
      return true
    end
  end

  def get_total_invoiced_amount(start_date, end_date, loc_params, doctor_params)
    total_amount = 0
    start_date = start_date.to_date unless start_date.nil?
    end_date = end_date.to_date unless end_date.nil?
    invoices = []

    if loc_params.nil? && doctor_params.nil?
      if start_date.nil? && end_date.nil?
        invoices = self.invoices
      else
        invoices = self.invoices.where(["issue_date >= ? AND issue_date <= ?", start_date, end_date])
      end
    elsif !(loc_params.nil?) && (doctor_params.nil?)
      if start_date.nil? && end_date.nil?
        invoices = self.invoices.joins(:business).where(["businesses.id = ?", loc_params])
      else
        invoices = self.invoices.joins(:business).where(["businesses.id = ? AND issue_date >= ? AND issue_date <= ?", loc_params, start_date, end_date])
      end
    elsif (loc_params.nil?) && !(doctor_params.nil?)
      if start_date.nil? && end_date.nil?
        invoices = self.invoices.joins(:user).where(["users.id = ?", doctor_params])
      else
        invoices = self.invoices.joins(:user).where(["users.id = ? AND issue_date >= ? AND issue_date <= ?", doctor_params, start_date, end_date])
      end
    elsif !(loc_params.nil?) && !(doctor_params.nil?)
      if start_date.nil? && end_date.nil?
        invoices = self.invoices.joins(:user, :business).where(["businesses.id = ? AND users.id = ? ", 2, 2]).uniq.count
      else
        invoices = self.invoices.joins(:user, :business).where(["users.id = ? AND businesses.id = ? AND issue_date >= ? AND issue_date <= ?", doctor_params, loc_params, start_date, end_date])
      end
    end

    invoices.each do |inv|
      total_amount = total_amount + inv.invoice_amount
    end
    return total_amount
  end

  def get_primary_contact(num = nil)
    number = nil
    contact_list = self.patient_contacts.map(&:contact_no)
    sms_log = self.sms_logs.last
    if num.nil?
      unless sms_log.nil?
        sms_from_no = sms_log.try(:contact_from)
        sms_from = contact_list.try(:first)
        contact_list.compact.map { |k| sms_from = k if sms_from_no.include? k }
        sms_to = sms_log.try(:contact_to)

        if contact_list.include? sms_from
          number = sms_from
        elsif contact_list.include? sms_to
          number = sms_to
        else
          number = contact_list.length > 0 ? contact_list.first : nil
        end
      else
        number = contact_list.length > 0 ? contact_list.first : nil
      end
    else
      number = num
    end
    number = number.phony_formatted(format: :international, spaces: '-') unless number.nil?
    return number
  end

  def get_previous_conversations(mno)
    result = []
    comp = self.company
    mob_no = self.get_primary_contact(mno).phony_formatted(format: :international, spaces: '').phony_normalized
    sms_logs = SmsLog.where(["(contact_to LIKE ? OR contact_from LIKE ?) AND company_id = ? AND object_id = ?", "%#{mob_no}%", "%#{mob_no}%", comp.id, self.id]).order("created_at desc")
    sms_logs.each_with_index do |log, index|
      item = {}
      item[:sms_body] = log.sms_text
      item[:sent_time] = log.formatted_delivered_time
      item[:direction] = log.status == "Received" ? "inbound" : "outbound"
      item[:status] = log.status
      result << item
    end

    return result

  end

  def self.koala(auth)
    access_token = auth['token']
    facebook = Koala::Facebook::API.new(access_token)
    profile = facebook.get_object('me?fields=name,picture,email,birthday,location, hometown , gender')
    #profile = facebook.get_object('me', {fields: 'name,picture,email,birthday,location, hometown , gender'})
    profile_img_url = facebook.get_picture(profile['id'], type: :large)
    return profile_img_url, profile
  end


  def merge_blank_attributes(ptnt)
    self.title = ptnt.title if (self.title.nil? || self.title.blank?)
    self.reminder_type = ptnt.reminder_type if (self.reminder_type.nil? || self.reminder_type.blank?)
    self.email = ptnt.email if (self.email.nil? || self.email.blank?)
    self.address = ptnt.address if (self.address.nil? || self.address.blank?)
    self.country = ptnt.country if (self.country.nil? || self.country.blank?)
    self.state = ptnt.state if (self.state.nil? || self.state.blank?)
    self.city = ptnt.city if (self.city.nil? || self.city.blank?)
    self.postal_code = ptnt.postal_code if (self.postal_code.nil? || self.postal_code.blank?)
    self.invoice_to = ptnt.invoice_to if (self.invoice_to.nil? || self.invoice_to.blank?)
    self.invoice_email = ptnt.invoice_email if (self.invoice_email.nil? || self.invoice_email.blank?)
    self.invoice_extra_info = ptnt.invoice_extra_info if (self.invoice_extra_info.nil? || self.invoice_extra_info.blank?)
    self.occupation = ptnt.occupation if (self.occupation.nil? || self.occupation.blank?)
    self.emergency_contact = ptnt.emergency_contact if (self.emergency_contact.nil? || self.emergency_contact.blank?)
    self.medicare_number = ptnt.medicare_number if (self.medicare_number.nil? || self.medicare_number.blank?)
    self.reference_number = ptnt.reference_number if (self.reference_number.nil? || self.reference_number.blank?)
    self.notes = ptnt.notes if (self.notes.nil? || self.notes.blank?)
    self.extra_info = ptnt.extra_info if (self.extra_info.nil? || self.extra_info.blank?)
    self.dob = ptnt.dob if (self.dob.nil? || self.dob.blank?)
    self.enate_id = ptnt.enate_id.present? ? ptnt.enate_id : self.enate_id
    self.save
    ptnt.patient_contacts.each do |ptn_contact|
      self.patient_contacts.create(contact_no: ptn_contact.contact_no , contact_type: ptn_contact.contact_type) if (self.has_phone_number(ptn_contact.contact_no , ptn_contact.contact_type))
    end
  end

  def has_phone_number(c_no , c_type)
    self.patient_contacts.where(contact_no: c_no , contact_type: c_type).length == 0
  end

  def get_first_appt_date
    self.appointments.active_appointment.order('appnt_date asc').first.try(:appnt_date)
  end

  def get_first_appt_time
    appnt  = self.appointments.active_appointment.order('appnt_date asc').first
    return appnt.nil? ? nil : (appnt.appnt_time_start.strftime('%H:%M %P') + " - "  + appnt.appnt_time_end.strftime('%H:%M %P'))
  end

  def get_most_recent_appt_date
    appnt  = self.appointments.active_appointment.where(['(Date(appnt_date) <= ? AND appnt_time_start  < CAST(?  AS time)) OR Date(appnt_date) < ?' , Date.today , Time.now , Date.today ]).order('created_at desc').first
    return appnt.try(:appnt_date)
  end

  def get_most_recent_appt_time
    appnt  = self.appointments.active_appointment.where(['(Date(appnt_date) <= ? AND appnt_time_start  < CAST(?  AS time)) OR Date(appnt_date) < ?' , Date.today , Time.now , Date.today ]).order('created_at desc').first
    return appnt.nil? ? nil : (appnt.appnt_time_start.strftime('%H:%M %P') + " - "  + appnt.appnt_time_end.strftime('%H:%M %P'))
  end

  def get_next_appt_date
    appnt  = self.appointments.active_appointment.where(['(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time)) OR Date(appnt_date) > ?' , Date.today , Time.now , Date.today ]).order('created_at desc').first
    return appnt.try(:appnt_date)
  end

  def get_next_appt_time
    appnt  = self.appointments.active_appointment.where(['(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time)) OR Date(appnt_date) > ?' , Date.today , Time.now , Date.today ]).order('created_at desc').first
    return appnt.nil? ? nil : (appnt.appnt_time_start.strftime('%H:%M %P') + " - "  + appnt.appnt_time_end.strftime('%H:%M %P'))
  end


  private

  def set_age
    unless self.dob.nil?
      birthday = "#{self.dob}".to_date()
      now = Time.now.utc.to_date
      age = get_age(now, birthday)
      self.age = age
    end
  end

  def get_age(now, birthday)
    age_diff = Time.diff(now, birthday)
    obj = ""
    if age_diff[:year] > 0
      if age_diff[:year] > 1
        obj = "#{age_diff[:year]} years"
      else
        obj = "#{age_diff[:year]} year"
      end
    else
      unless age_diff[:month] == 0
        if age_diff[:month] > 1
          obj = "#{age_diff[:month]} months"
        else
          obj = "#{age_diff[:month]} month"
        end
      else
        obj = "#{age_diff[:month]} month"
      end
    end
  end
end
