class User < ActiveRecord::Base
  # acts_as_google_authenticated :lookup_token => :id, :issuer => 'Opustime'
  has_one_time_password column_name: :google_secret
  include Authentication
  include Opustime::Utility

  # adding indentification key through concern
  include IdentificationKey

  # serialize :phone , Array

  attr_accessor :temp_password # containing password temporary for Action mailer
  attr_accessor :remember_token
  attr_accessor :user_type


  # paperclip attachment into user
  has_attached_file :image, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/images/:style/missing.png"
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  has_attached_file :logo,
                    styles: { medium: "300x300>", thumb: "100x100>" },
                    :url => "attachments/company/:company_id/logos/users/:id/:extension/:basename.:extension" ,
                    :path => "public/attachments/:company_id/logos/users/:id/:extension/:basename.:extension"
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/
  validates_attachment_size :logo, :less_than => 2.megabytes

  Paperclip.interpolates :company_id do |attachment, style|
    attachment.instance.company_id
  end


  scope :doctors, -> { where("users.is_doctor= ? AND users.acc_active=?", true, true).order("users.created_at asc") }
  scope :active_user, -> { where("acc_active=?", true) }
  scope :admin, -> { where("role=?", "administrator") }

  # validates_uniqueness_of :email 

  #   To send email/password on user creation
  # after_create :send_email
  before_save :keep_password

  belongs_to :company
  has_one :practi_info, :dependent => :destroy

  accepts_nested_attributes_for :practi_info, :allow_destroy => true #, :reject_if => "role.casecmp('practitioner')" # lambda { |a| a[:business_id].nil? || a[:business_id].blank?  }, :allow_destroy => true
  validates_associated :practi_info

  # validates :password, confirmation: true

  # validates_presence_of :practi_info , :if =>  :should_be_doctor? 

  has_many :practi_refers, :through => :practi_info, :dependent => :destroy
  # has_many :practi_avails , :through=> :practi_info , :dependent=> :destroy

  has_many :practitioner_avails, :through => :practi_info, :dependent => :destroy
  has_one :client_filter_choice, :dependent => :destroy

  has_many :appointments, :dependent => :destroy
  has_many :patients, :through => :appointments, :dependent => :destroy

  has_many :wait_lists_users, :dependent => :destroy
  has_many :wait_lists, :through => :wait_lists_users, :dependent => :destroy

  has_many :appointment_types_users, :dependent => :destroy
  has_many :appointment_types, :through => :appointment_types_users, :dependent => :destroy
  accepts_nested_attributes_for :appointment_types_users, :allow_destroy => true

  has_one :user_roles_user, :dependent => :destroy
  has_one :user_role, :through => :user_roles_user, :dependent => :destroy
  # accepts_nested_attributes_for :users_role , :allow_destroy => true

  has_many :invoices_users, :dependent => :destroy
  has_many :invoices, :through => :invoices_users, :dependent => :destroy

  has_many :availabilities, :dependent => :destroy
  # has_many :sms_logs , :dependent => :destroy
  has_many :sms_logs, :as => :object, :dependent => :destroy

  has_one :appointment_state, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_many :comments, :through => :posts, :dependent => :destroy

  has_many :expenses , :dependent => :destroy

  has_many :activities_as_owner, :class_name => "::PublicActivity::Activity", :as => :owner
  has_many :imports , :dependent => :destroy


  #---------------- Commented extra validations callback ----------------------#
  # before_update :validate_email
  # before_create :validate_email
  #---------------- Commented extra validations callback ----------------------#

  before_save :validate_email, :if => Proc.new { |user| user.user_type.blank? }

  # nested attributes for practi_info model begin here ---
  # accepts_nested_attributes_for :practi_info, :allow_destroy => true
  # ending here

  after_commit :assign_doctors_appointments,:if => Proc.new { |user| user.user_type.blank? }

  after_create :update_combine_ids,:if => Proc.new { |user| user.user_type.blank? }


  def update_combine_ids
    self.update_columns(:combine_ids => "#{self.company.id}-#{self.id}")
  end

  #validates_presence_of :password , :on=> [:create, :update] , :message=>"password can't be left blank"
  #validates :password, presence: true, confirmation: true, length: {minimum: 6, maximum: 20}, :allow_nil => true
  validates :password, presence: true, confirmation: true, :allow_nil => true
  validates_format_of :password, :with => /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/i, :message => "a password must be eight characters including one uppercase letter, one special character and alphanumeric characters.", :multiline => true, :on => [:create, :update], :allow_nil => true

  validates_presence_of :email, :first_name, :last_name, :on => [:create, :update]

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :on => [:create, :update]

  # later validation 
  # validates :password , confirmation: true  , :on=> :update
  # validates :password , confirmation: true  , :on=> [:update , :create]
  # validates :password_confirmation , presence: true  , :on=> [:update , :create]

  # validates :phone, :allow_nil => true,
  #           :allow_blank => true,
  #           :numericality => {:only_integer => true},
  #           :length => {:minimum => 10}

  validates_plausible_phone :phone, :allow_nil => true,
                            :allow_blank => true,
                            :numericality => true ,
                            :message => 'Invalid phone.Please check country in Account tab.'

  before_validation :normalize_contact_number

  def normalize_contact_number
    phone_no = PhonyRails.normalize_number(phone, country_code: user_country_code(self))
    phone_no = phone if phone_no.nil?
    self.phone = phone_no
  end

  # validate :must_be_unique_email

  # ending here -----
  def should_be_doctor?
    is_doctor == true
  end

  def keep_password
    self.temp_password = self.password
  end

  # def country_code
  #   company.account.country rescue nil
  #   nil
  # end

  # def send_email
  # UserMailer.welcome_email(self ,self.temp_password ).deliver
  # end

  def full_name
    (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
  end

  def full_name_with_title
    self.title.to_s.capitalize + ((self.title.to_s.casecmp('master') == 0 || self.title.to_s.blank?) ? ' ':'. ') + (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
  end

  def full_name_with_title_and_info(bs_id)
    full_name = self.title.to_s.capitalize + ((self.title.to_s.casecmp('master') == 0 || self.title.to_s.blank?) ? ' ':'. ') + (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
    refers = self.practi_refers.where(['practi_refers.business_id =? ' , bs_id ]).select('practi_refers.ref_type , practi_refers.number')
    refers_str = ''
    refers.each_with_index do |refer , index|
      refers_str = refers_str + ' , ' if index > 0
      refers_str = refers_str + refer.ref_type.to_s
      refers_str = refers_str + (refer.number.nil? ? '' : ': ' + refer.number.to_s)
    end
    if refers_str.blank?
      return full_name
    else
      return full_name + "(#{refers_str})"
    end


  end


  def assign_doctors_appointments
    if self.user_role.nil?
      role = UserRole.find_by_name(self.role.downcase)
      user_role = UserRolesUser.find_or_initialize_by(user_id: self.id, user_role_id: role.id)
      if user_role.valid?
        user_role.save
      end
    else
      role = UserRole.find_by_name(self.role.downcase)
      user_role = UserRolesUser.find_or_initialize_by(user_id: self.id, user_role_id: self.user_role.id)
      user_role.update_attributes(user_role_id: role.id)
    end
  end

  # Functionality for Remember me and Forget password

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
        BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Ending here
  # Forget password functionality


  def send_password_reset
    self.password_reset_token = User.new_token
    self.password_reset_sent_at = Time.zone.now
    save!
  end

  def total_active_appointments
    self.appointments.active_appointment.count
  end

  def validate_email
    company = self.company
    if self.new_record?
      existing_users_emails = company.users.doctors.map(&:email)
    else
      existing_users_emails = company.users.doctors.where(["id != ?", self.id]).map(&:email)
    end
    self.errors.add(:email, "has been taken already!") if existing_users_emails.include?(self.email)
  end

  def total_revenues
    revenue = 0.0
    invoices = self.invoices.active_invoice
    invoices.each do |invoice|
      revenue = revenue + invoice.total_paid_money_for_invoice
    end
    return revenue
  end

  def rised_invoices_amount(loc = nil, date = nil)
    amount = 0.0
    if loc.nil? && date.nil?
      @invoices = self.invoices.active_invoice
    else
      @invoices = self.invoices.active_invoice.joins(:business).where(["Date(invoices.issue_date) = ? AND businesses.id = ? ", date, loc])
    end
    @invoices.each do |invoice|
      amount = amount + invoice.total_amount
    end
    return amount
  end

  def closed_invoices_amount(loc = nil, date = nil)
    amount = 0.0
    if loc.nil? && date.nil?
      @invoices = self.invoices.active_invoice
    else
      @invoices = self.invoices.active_invoice.joins(:business).where(["Date(invoices.issue_date) = ? AND businesses.id = ? ", date, loc])
    end
    @invoices.each do |invoice|
      if invoice.calculate_outstanding_balance == 0
        amount = amount + invoice.total_amount
      end
    end
    return amount
  end

  def opened_invoices_amount(loc = nil, date = nil)

    amount = 0.0
    if loc.nil? && date.nil?
      @invoices = self.invoices.active_invoice
    else
      @invoices = self.invoices.active_invoice.joins(:business).where(["Date(invoices.issue_date) = ? AND businesses.id = ? ", date, loc])
    end

    @invoices.each do |invoice|
      if invoice.calculate_outstanding_balance > 0
        amount = amount + invoice.calculate_outstanding_balance
      end
    end
    return amount
  end

  def self.to_csv(options = {})
    column_names = ["PROFESSIONALS", "APPOINTMENTS", "RISED_INVOICES",
                    "CLOSED_INVOICES", "OPENED_INVOICES", "TOTAL_REVENUES"]
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |doctor|
        data = []
        data << doctor.full_name_with_title.gsub(" ", "")
        data << doctor.total_active_appointments
        data << doctor.rised_invoices_amount
        data << doctor.closed_invoices_amount
        data << doctor.opened_invoices_amount
        data << doctor.total_revenues
        csv << data
      end
    end

  end

  def get_primary_contact
    self.phone.nil? ? (self.phone) : (self.phone.phony_formatted(format: :international, spaces: '-'))
  end

  def get_previous_conversations
    result = []
    comp = self.company
    mob_no = self.get_primary_contact.phony_formatted(format: :international, spaces: '')
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

  def total_pending_appnts(loc, date)
    self.appointments.joins(:business).where(["(businesses.id = ? AND appointments.status = ? AND DATE(appointments.appnt_date) = ? AND (appointments.appnt_status IS NULL OR appointments.appnt_status = false) )", loc, true, date]).count
  end

  def total_cancelled_appnts(loc, date)
    self.appointments.joins(:business).where(["businesses.id = ? AND appointments.status = ? AND DATE(appointments.appnt_date) = ? AND appointments.cancellation_time IS NOT ?", loc, false, date, nil]).count
  end

  def total_processed_appnts(loc, date)
    self.appointments.joins(:business).where(["businesses.id = ? AND appointments.status = ? AND DATE(appointments.appnt_date) = ? AND appointments.appnt_status = ?", loc, true, date, true]).count
  end

  # ending    
end
