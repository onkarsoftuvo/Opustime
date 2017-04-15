class TempSection < ActiveRecord::Base
  belongs_to :template_note
  has_one :company
  
  has_many :questions , :dependent=> :destroy
  has_many :quest_choices , :through=> :questions , :dependent=> :destroy
  
  accepts_nested_attributes_for :questions , allow_destroy: true
  
#   later validations

  # validates :name  , presence: true 
  
# ending here 
   
end
