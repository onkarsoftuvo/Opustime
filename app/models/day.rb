class Day < ActiveRecord::Base
  belongs_to :practitioner_avail
  before_save :check_practitioner_in_availability
  before_update :check_practitioner_in_availability

  has_many :practitioner_breaks , :dependent=> :destroy 
  accepts_nested_attributes_for :practitioner_breaks , :allow_destroy => true
  validates_associated :practitioner_breaks
  # validates :practitioner_breaks, :presence=> true ,  :allow_nil=> true
  def check_practitioner_in_availability
    start_time =  self.start_hr.to_i+(self.start_min.to_i*0.01)
    end_time =  self.end_hr.to_i+(self.end_min.to_i*0.01)
   # break_start_time = self.start_hr.to_i+(self.start_min.to_i*0.01)
   # break_end_time =  self.end_hr.to_i+(self.end_min.to_i*0.01)
    user = self.practitioner_avail.practi_info.user
    user.errors.add(:practitioner , "does not exist in available time") unless ((end_time > start_time ))
    return false if user.errors.count > 0
  end
end
