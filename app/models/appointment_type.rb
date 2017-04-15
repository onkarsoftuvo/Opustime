class AppointmentType < ActiveRecord::Base
  serialize :prefer_practi , JSON
  serialize  :billable_item , Array
  serialize  :related_product , Array
  
  has_associated_audits
  
  has_many :appointment_types_wait_lists , :dependent=> :destroy
  has_many :wait_lists , :through=> :appointment_types_wait_lists ,:dependent=> :destroy
  
  has_many :appointment_types_billable_items , :dependent=> :destroy
  has_many :billable_items , :through=> :appointment_types_billable_items  ,  :dependent=> :destroy
  accepts_nested_attributes_for :appointment_types_billable_items , :allow_destroy => true
  
  has_many :appointment_types_products , :dependent=> :destroy
  has_many :products , :through=> :appointment_types_products  ,  :dependent=> :destroy
  accepts_nested_attributes_for :appointment_types_products , :allow_destroy => true

  has_many :appointment_types_users , :dependent=> :destroy
  has_many :users , -> { where("is_doctor= ? AND acc_active=?" , true, true) } , :through=> :appointment_types_users  ,  :dependent=> :destroy
  accepts_nested_attributes_for :appointment_types_users , :allow_destroy => true 
  
  has_one :appointment_types_invoice ,  :dependent => :destroy
  has_one :invoice , :through=> :appointment_types_invoice ,  :dependent => :destroy

  
  has_one :appointment_types_template_note ,  :dependent => :destroy
  has_one :template_note , :through=> :appointment_types_template_note,  :dependent => :destroy
  accepts_nested_attributes_for :appointment_types_template_note, :allow_destroy => true
    
  # attr_accessible :name, :prefer_practi ,  :description, :category , :duration_time, :billable_item ,:default_note_template ,:related_product , :color_code, :reminder ,  :confirm_email, :send_reminder , :allow_online , :company_id
  
  belongs_to :company
  
  has_many :appointment_types_appointments , :dependent=> :destroy
  has_many :appointments , :through => :appointment_types_appointments , :dependent=> :destroy
  
#   later validations 
  validates_presence_of :name
  validates :duration_time ,  numericality: { only_integer: true , :greater_than_or_equal_to=> 0 , :less_than_or_equal_to => 360 } ,
                              presence: true 
                              
  
# ending here ----
  
end
