class PractitionerBreak < ActiveRecord::Base
  belongs_to :day
  
  before_save :check_breaks_exist_in_availability
  before_update :check_breaks_exist_in_availability

# validation for -  practitioner breaks must be exist within availability time.   
  def check_breaks_exist_in_availability
    start_time =  self.day.start_hr.to_i+(self.day.start_min.to_i*0.01)
    end_time =  self.day.end_hr.to_i+(self.day.end_min.to_i*0.01)
    break_start_time = self.start_hr.to_i+(self.start_min.to_i*0.01)
    break_end_time =  self.end_hr.to_i+(self.end_min.to_i*0.01)
    user = self.day.practitioner_avail.practi_info.user
    user.errors.add(:break , "does not exist in available time") unless ((break_start_time > start_time && break_start_time < end_time) && (break_end_time < end_time && break_end_time > start_time) &&  (break_start_time < break_end_time))
    return false if user.errors.count > 0
  end
end
