class TreatmentNote < ActiveRecord::Base
  belongs_to :patient
  
  has_many :treatment_sections , :dependent => :destroy
  has_many :treatment_questions , :through=> :treatment_sections,   :dependent => :destroy
  
  accepts_nested_attributes_for :treatment_sections , :allow_destroy => true
  validates :patient , presence: true
  validates_presence_of :treatment_notes_template_note
  scope :active_treatment_note, ->{ where(status: true)}
  
  has_one :treatment_notes_template_note , :dependent=> :destroy
  has_one :template_note , :through=> :treatment_notes_template_note , :dependent=> :destroy
  
  accepts_nested_attributes_for :treatment_notes_template_note , 
                                :reject_if => lambda { |a| a[:template_note_id].nil? || a[:template_note_id].blank?  }, 
                                :allow_destroy => true
                                
  has_one :treatment_notes_appointment , :dependent=> :destroy
  has_one :appointment , :through=> :treatment_notes_appointment , :dependent=> :destroy
   
  accepts_nested_attributes_for :treatment_notes_appointment , 
                                :allow_destroy => true                             
                                
  before_save :set_current_user_to_treatment_note
  
  def set_current_user_to_treatment_note
    current_user = Thread.current[:user] 
    self.created_by_id = current_user.id
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  def practitioner_name
    doctor_id = self.created_by_id
    name = " "
    if doctor_id.to_i > 0 
      name = User.find(doctor_id).try(:full_name)
    end
    return name 
  end

  def paper_format
    format = ""
    sections  = self.treatment_sections
    sections.each do |section|
      format  = "Section : " + section.name.to_s + "**"
      section.treatment_questions.each do |qs|
        format = format + "[Question: " + qs.title.to_s + "]"
        qs.treatment_quest_choices.each do |choice|
          format = format + " - " + choice.title.to_s
          quest_answer = choice.treatment_answer
          format = format + " - " + quest_answer.is_selected.to_s unless ["Text","Paragraph"].include?qs.quest_type
          format = format + " - " +  quest_answer.ans.to_s if ["Text","Paragraph"].include?qs.quest_type
        end 
      end
    end
    return format 

  end
  
end