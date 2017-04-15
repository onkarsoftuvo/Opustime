class FileAttachment < ActiveRecord::Base
  belongs_to :patient
  
  has_attached_file :avatar ,
               :url => "attachments/patients/:patient_id/:extension/:id/:basename.:extension" ,   
               :path => "public/attachments/patients/:patient_id/:extension/:id/:basename.:extension"

    validates_attachment_size :avatar, :less_than => 10.megabytes    
    validates_attachment_presence :avatar 
    validates_attachment_content_type :avatar, :content_type => ["application/pdf","application/vnd.ms-excel",     
             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
             "application/msword", 
             "application/vnd.openxmlformats-officedocument.wordprocessingml.document", 
             "text/plain" , /\Aimage\/.*\Z/],:message => ', Only PDF, EXCEL, WORD or TEXT files are allowed. '
  
  before_save :set_current_user_to_file_attachment
  
  def set_current_user_to_file_attachment
    current_user = Thread.current[:user] 
    self.created_by = current_user.id unless current_user.nil?
    
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  def find_uploader
    User.find_by_id(self.created_by).try(:full_name) 
  end

end
