class SmsTemplate < ActiveRecord::Base
  belongs_to :company
  serialize :addition_tabs , JSON
   
  validates :template_name , :body , presence: true 

  scope :active_letter, ->{ where(status: true)}
  
  before_create :set_additional_tabs , :if=> "addition_tabs.nil?"
  
   
  def set_additional_tabs
    self.addition_tabs = {practitioner: false , business: false , contact: false}
  end

end
