class Company < ActiveRecord::Base
  include Authentication
  
  serialize :calendar_setting , JSON
  attr_accessor :total_sms_payment,:total_plan_payment

  attr_accessible  :company_name , :first_name , :last_name,
   :email , :password ,  :country, :time_zone , :attendees, :communication_email, :calendar_setting,
   :patient_name_by , :multi_appointment, :show_time_indicator ,:note_letter , 
   :show_finance, :show_attachment , :logo , :company_status
   
   before_save :default_values , :default_calendar_settings

  scope :last_sms_payment, ->(company) do
    record = company.transactions.where(:transaction_type => 'SP').where(:error_status => false).sort_by(&:created_at).last
    last_payment = record.amount rescue 0
    payment_date = record.created_at.try(:strftime, '%d %B %Y,  %H:%M:%S %p') rescue nil
    [last_payment, payment_date]
  end


  attr_accessible :company_name, :first_name, :last_name,
                  :email, :password, :country, :time_zone, :attendees, :communication_email, :calendar_setting,
                  :patient_name_by, :multi_appointment, :show_time_indicator, :note_letter,
                  :show_finance, :show_attachment, :logo, :company_status , :terms

  before_save :default_values, :default_calendar_settings

  has_attached_file :logo,
               styles: { medium: "300x300>", thumb: "100x100>" },
               default_url: "/assets/missing.png"
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/


  # after_save :add_sms_group
  #
  #
  # def add_sms_group
  #   sms_group_country = SmsGroupCountry.find_by_country(self.country)
  #   if sms_group_country.present?
  #     self.update_column(:sms_group_id, sms_group_country.sms_group_id)
  #   else
  #     default_grp = SmsGroup.find_by(name: 'Default')
  #     self.update_column(:sms_group_id, default_grp.id)
  #   end
  # end
  
  # Explicitly do not validate
  do_not_validate_attachment_file_type :logo
  
#   all models associations  for setting module
  # Quickbooks start
  has_many :qbo_accounts,:dependent => :destroy
  has_one :quick_book_info,:dependent => :destroy
  has_many :qbo_logs,:dependent => :destroy
  # Quickbooks end

  # Authorizenet start
  has_many :transactions,:dependent => :destroy
  has_many :cancel_subscriptions,:dependent => :destroy
  # Authorizenet stop


  has_many :attempts , :dependent=> :destroy
  has_one :account , :dependent=> :destroy
  has_many :businesses , :dependent=> :destroy
  has_many :users  , :dependent=> :destroy
  has_many :appointment_types   , :dependent=> :destroy
  has_many :billable_items , :dependent=> :destroy
  has_many :payment_types , :dependent=> :destroy
  has_many :recall_types , :dependent=> :destroy  
  has_many :tax_settings , :dependent=> :destroy
  has_many :template_notes , :dependent=> :destroy
  has_many :concessions , :dependent=> :destroy
  has_many :temp_sections , :through=> :template_notes , :dependent=> :destroy
  has_one :online_booking , :dependent=> :destroy
  has_many :letter_templates , :dependent => :destroy
  has_many :sms_templates , :dependent => :destroy
  has_many :referral_types , :dependent => :destroy
  has_one :invoice_setting , :dependent => :destroy 
  has_one :document_and_printing, :dependent => :destroy
  has_one :appointment_reminder,  :dependent => :destroy
  has_one :sms_setting , :dependent=> :destroy
  has_one :sms_credit , :through=> :sms_setting , :dependent=> :destroy  
  has_one :subscription , :dependent=> :destroy
  has_one :mail_chimp_info , :dependent=> :destroy
  has_one :xero_session , :dependent=> :destroy
  has_many :facebook_pages , :dependent=> :destroy
  has_many :exports , :dependent=> :destroy
  has_many :imports , :dependent=> :destroy
  has_many :sms_logs , :dependent=> :destroy
  has_one :sms_number , :dependent=> :destroy
  has_many :posts , :through => :users , :dependent=> :destroy
  has_one :quick_book_info , :dependent=> :destroy
  has_one :dashboard_report , :dependent=> :destroy
  has_many :payment_histories, :dependent=> :destroy
  
#   ending here ----

  has_many :products , :dependent => :destroy
  has_many :product_stocks , :through=> :products , :dependent => :destroy
  
  has_many :expenses , :dependent => :destroy
  has_many :expense_categories , :dependent => :destroy
  has_many :expense_vendors  ,:dependent => :destroy

  has_many :contacts , :dependent => :destroy
  has_many :patients , :dependent => :destroy
  has_many :invoices , :through=> :patients , :dependent => :destroy
  has_many :treatment_notes , :through=> :patients , :dependent => :destroy
  has_many :file_attachments , :through=> :patients , :dependent => :destroy
  has_many :recalls , :through=> :patients , :dependent => :destroy


  has_many :invoice_items , :through=> :invoices , :dependent => :destroy

  has_many :letters , :through=> :patients , :dependent => :destroy
  has_many :payments , :through=> :patients , :dependent => :destroy
  has_many :communications , :through=> :patients , :dependent => :destroy
  has_many :appointments , :through=> :patients , :dependent => :destroy
  has_many :wait_lists , :dependent=> :destroy
  has_one :facebook_detail, :dependent => :destroy
  validates_presence_of :company_name , :on=> [:create,:update] , :message=>" company name can't be left blank"
  validates_presence_of :email , :on=> :create , :message=>"email can't be left blank"  
  validates_presence_of :password , :on=> :create , :message=>"password can't be left blank"
  
  # validates_presence_of :first_name , :on=> :update , :message=> "first name can't be left blank"
  # validates_presence_of :last_name , :on=> :update , :message=> "last name can't be left blank"
  # validates_presence_of :country ,  :time_zone , :on=> :update
#   
  # VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates_uniqueness_of :company_name , :message=>"Company name already exists"
  validates_format_of :email , :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i , :message=> " doesn't look like an email address"
  #validates :password , length: { in: 8..20 , :message=>"password's length must be in between 8 to 20 characters"} , :on=>:create
  #validates_uniqueness_of :email , :message=>"Email name already exists"
#   validations for test cases at last 
  validates_format_of :password, :with => /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/i, :message=> " password's Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character",:multiline => true,:on=>:create
  validates :company_name , :length => { :maximum => 50,
    :too_long => "%{count} characters is the maximum allowed" }
  
  validates_presence_of :communication_email , presence: true , :on=>:update
  validates :attendees , inclusion: { in: %w(members patients clients),
    message: "%{value} is not a valid attendee" }

  # after_commit :update_system_cronjob , :unless=> 'status'
  #
  # # callback for cronjob on company a/c deactivated
  # def update_system_cronjob
  #   system "cd #{Rails.root};  whenever --update-crontab "
  # end

#   ending here -------

  def default_values
    self.communication_email ||= self.email
  end
  
  def default_calendar_settings
    self.calendar_setting ||= {:size=>"15" , :height=>"small" , :time_range => {:min_time=> "7" , :max_time=>"22" , :min_minute=>"0" , :max_minute => "0"} }
  end

  def full_name
    self.first_name.to_s + " " + self.last_name.to_s
  end

  def get_payment_types_names
    self.payment_types.map(&:name)
  end

  #added by manoranjan
  def get_revenue_collection
    tot = 0
    self.payments.active_payment.map{|h| tot = tot + h.get_paid_amount}
    return tot
  end
  def earning_from_sms
    sum = 0
    earn_sms = self.payment_histories.where(["paymentable_type=?" , "SmsPlan"]).map{|k| sum = sum + k.paymentable.amount.to_i}
    return sum
  end


  def earning_from_subscription
    sum = 0
    earn_sms = self.payment_histories.where(["paymentable_type=?" , "Plan"]).map{|k| sum = sum + k.paymentable.price.to_i}
    return sum
  end

  def revenue_total
    total = get_revenue_collection + earning_from_sms + earning_from_subscription
    return total
  end

  def get_reminder_day_time
    return self.appointment_reminder.reminder_time_in_utc
  end

  def find_admin
    self.users.where(['role = ?' , ROLE[5]]).first
  end

  # using this method to create cronjob on the reminder setting basis
  def cancel_confirm_apnt_sms_reminder
    # self.patients.last.update(notes: Time.now.to_s)
    reminder_setting = self.appointment_reminder
    unless (reminder_setting.skip_weekends && (["0","6"].include?(Time.now.strftime("%w"))))
      ReminderWorker.perform_async(self.id)
    end

  end

end
