class Account < ActiveRecord::Base
  belongs_to :company
  
  serialize :calendar_setting , JSON
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i   # Regular Expression to check valid
  
  has_attached_file :logo,
               # styles: { medium: "300x300>", thumb: "100x100>" },
               :url => "attachments/company/:company_id/logos/:extension/:id/:basename.:extension" ,
               :path => "public/attachments/companies/:company_id/logos/:extension/:id/:basename.:extension"
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

  Paperclip.interpolates :company_id do |attachment, style|
    attachment.instance.company_id
  end
  
  # Explicitly do not validate
  do_not_validate_attachment_file_type :logo
  
#  valildation for setting calendar  
  validate :check_calendar_setting    
  
  validates :company_name , presence:true , :length => { :maximum => 50,
    :too_long => "%{count} characters is the maximum allowed" }
  
  validates_presence_of :communication_email , presence: true , :on=>:update
  validates_format_of :communication_email , :with => VALID_EMAIL_REGEX , :message=> " doesn't look like an email address"
  
  def owner
    self.first_name.to_s + " " + self.last_name.to_s
  end
    
  
  def check_calendar_setting
    if calendar_setting["time_range"]["max_time"].to_i <= calendar_setting["time_range"]["min_time"].to_i
      errors.add(:account_setting_calendar, "end hour needs to be later than calendar start hour.")
    end
  end
  
end
