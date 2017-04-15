APPOINTMENT_NAMES = ["First Appointment", "Standard Appointment"]
BILLABLE_ITEM_NAMES = ["Initial consultation and treatment" , "Standard consultation and treatment"]
CONCESSION_NAMES = ["Seniors","Students"]
# PAYMENT_TYPES = ["HICAPS","Credit Card","EFTPOS","Cash","Other"]
PAYMENT_TYPES = ["Credit Card","Cash","Other"]
RECALL_TYPES = ["Return visit","Return visit(soon)"]
TAXES = ["GST"]
TEMPLATE_NOTES_NAMES =["Initial Consultation","Standard Consultation"]
PLAN  =["Solo" ,"Team", "Medium", "Group","Large","University"]
STATUS = {0=> "inactive" , 1=> "active" , 2=>"archive" , 3=>"delete"}
COMPANY_STATUS = {0=> "active" , 1=> "inactive" , 2=>"trial_user"}
ROLE  = {0=> "scheduler" , 1=> "receptionist" , 2=>"practitioner" , 3=>"bookkeeper" , 4=>"power receptionist" ,5=>"administrator"}
ADMIN_ROLE = {0=> 'admin_user' , 1=> 'sales_user' , 2=> 'marketing_user'}
BUSINESS_TYPE = {0=> "secondary", 1=> "primary"}
INITIAL_TREATMENT_NOTE_QUESTIONS = ["Presenting complaint", "Complaint history" , "Medical history", "Medication", "Assessment", "Treatment" , "Treatment plan"]
STANDARD_TREATMENT_NOTE_QUESTIONS = ["Patient progress report" , "Assessment" , "Treatment"]
CLIENT_EVENT_SIZE = 20
IMPORT_STATUS = {0=> "started" , 1=> "failed" , 2=>"complete"}
APPNT_SUMMARY = {"0"=>"New", "1"=>"Standard", "2"=>"Recurring", "3"=>"Cancelled", "4"=>"Missed", "5"=>"Rescheduled"}
LOG_STATUS  = {0 => "Delivered" , 1 => "Failed" , 2 => "Received"}
SMS_TYPE = {0 => "Bulk" , 1 => "Custom" , 2 => "System"}
SMS_TRIAL_NO = {stage: "+14389688251" , prod: "+12045152646"}
DEFAULT_THEME_NAME = "blue_theme"

RAILS_ROOT_PATH = Rails.root

LOG_PATH = Rails.env.production? ? '/home/ubuntu/opustime/shared' : Rails.root



Audited.current_user_method = :current_user


class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class Fixnum
  def to_bool
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class TrueClass
  def to_i; 1; end
  def to_bool; self; end
end

class FalseClass
  def to_i; 0; end
  def to_bool; self; end
end

class NilClass
  def to_bool; false; end
end
