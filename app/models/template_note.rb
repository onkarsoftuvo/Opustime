class TemplateNote < ActiveRecord::Base
  belongs_to :company
  has_many :temp_sections , :dependent=> :destroy
  has_many :questions , :through => :temp_sections , :dependent=> :destroy
  
  accepts_nested_attributes_for :temp_sections , allow_destroy: true
  
  has_many :appointment_types_template_notes ,  :dependent => :destroy
  has_many :appointment_types , :through=> :appointment_types_template_notes,  :dependent => :destroy
  
  
#   later validations

  validates :name  , presence: true 
  has_many :treatment_notes_template_notes , :dependent=> :destroy
  has_many :treatment_notes , :through=> :treatment_notes_template_notes , :dependent=> :destroy
  
# ending here 
end
