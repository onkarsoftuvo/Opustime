class LetterTemplate < ActiveRecord::Base
  belongs_to :company
  serialize :addition_tabs , JSON
   
  validates :template_name , :template_body , presence: true 
  scope :active_letter, ->{ where(status: true)}
  
  before_create :set_additional_tabs , :if=> "addition_tabs.nil?"
  
  has_many :letter_templates_letters , :dependent=> :destroy
  has_many :letters , :through=> :letter_templates_letters , :dependent=> :destroy
  
   
  def set_additional_tabs
    self.addition_tabs = {practitioner: false , business: false , contact: false}
  end
  
  
end
