class Question < ActiveRecord::Base
  belongs_to :temp_section
  has_many :quest_choices , :dependent=> :destroy
  
  accepts_nested_attributes_for :quest_choices , allow_destroy: true
  
  #   later validations

  # validates :title  , presence: true 
  
# ending here 
  
end
