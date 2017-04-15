class Letter < ActiveRecord::Base
  
  belongs_to :patient
  
  
  has_one :letter_templates_letter , :dependent=> :destroy
  has_one :letter_template , :through=> :letter_templates_letter , :dependent=> :destroy
  
  accepts_nested_attributes_for :letter_templates_letter , :reject_if => lambda { |a| a[:letter_template_id].nil? || a[:letter_template_id].blank?  }, :allow_destroy => true
  validates_presence_of :letter_templates_letter
  
  scope :active_letter , ->{where(status: true)} 
  before_save :set_current_user_to_letter  
  
  
  def set_current_user_to_letter 
    current_user = Thread.current[:user] 
    self.auther_id = current_user.id
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  def get_business_info
    bs_id = self.business
    name = " "
    unless bs_id.to_i <= 0 
      name = Business.find(bs_id).try(:name)
    end   
    return name 
  end

  def get_doctor_info
    doctor_id = self.practitioner
    name = " "
    unless doctor_id.to_i <= 0 
      name = User.find(doctor_id).try(:full_name_with_title)
    end   
    return name 
  end
  
  def get_contact_info
    contact_id = self.contact
    name = " "
    unless contact_id.to_i <= 0 
      name = Contact.find(contact_id).try(:full_name)
    end   
    return name 
  end
  
end
