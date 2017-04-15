class Owner < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_accessor :user_type

  has_many :plans , dependent: :destroy
  has_many :sms_plans , dependent: :destroy
  has_one :default_sm , dependent: :destroy

  has_one :user_roles_owner , dependent: :destroy
  has_one :user_role , :through => :user_roles_owner , dependent: :destroy

  has_one :dashboard_permission , dependent: :destroy
  has_one :appointment_permission , dependent: :destroy
  has_one :patient_permission , dependent: :destroy
  has_one :invoice_permission , dependent: :destroy
  has_one :payment_permission , dependent: :destroy
  has_one :product_permission , dependent: :destroy
  has_one :expense_permission , dependent: :destroy
  has_one :contact_permission , dependent: :destroy
  has_one :pntfile_permission , dependent: :destroy
  has_one :announcemsg_permission , dependent: :destroy
  has_one :userinfo_permission , dependent: :destroy
  has_one :communication_permission , dependent: :destroy
  has_one :medical_permission , dependent: :destroy
  has_one :treatnote_permission , dependent: :destroy
  has_one :letter_permission , dependent: :destroy
  has_one :recall_permission , dependent: :destroy
  has_one :report_permission , dependent: :destroy
  has_one :dataexport_permission , dependent: :destroy
  has_one :setting_permission , dependent: :destroy

  after_create :set_owner_user_role



  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100#" }, :default_url => "/images/:style/missing.png"
  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/
  validates_presence_of  :first_name, :last_name, :on => [:create, :update]
  # validates :password, confirmation: true,:allow_nil => true
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :on => [:create, :update]

  def full_name
    first_name+' '+last_name
  end

  def set_owner_user_role
    user_role = UserRole.find_by_name(self.role)
    UserRolesOwner.create(owner_id: self.id , user_role_id: user_role.id )
  end

  def self.permission_matrix
    result = {}
    result[:dashboard_permission] = DashboardPermission.get_exact_values
    result[:appointment_permission] = AppointmentPermission.get_exact_values
    result[:patient_permission] = PatientPermission.get_exact_values
    result[:pntfile_permission] = PntfilePermission.get_exact_values
    result[:invoice_permission] = InvoicePermission.get_exact_values
    result[:product_permission] = ProductPermission.get_exact_values
    result[:payment_permission] = PaymentPermission.get_exact_values
    result[:expense_permission] = ExpensePermission.get_exact_values
    result[:contact_permission] = ContactPermission.get_exact_values
    result[:announcemsg_permission] = AnnouncemsgPermission.get_exact_values
    result[:userinfo_permission] = UserinfoPermission.get_exact_values
    result[:communication_permission] = CommunicationPermission.get_exact_values
    result[:medical_permission] = MedicalPermission.get_exact_values
    result[:treatnote_permission] = TreatnotePermission.get_exact_values
    result[:letter_permission] = LetterPermission.get_exact_values
    result[:recall_permission] = RecallPermission.get_exact_values
    result[:report_permission] = ReportPermission.get_exact_values
    result[:dataexport_permission] = DataexportPermission.get_exact_values
    result[:setting_permission] = SettingPermission.get_exact_values
    return result
  end

end
