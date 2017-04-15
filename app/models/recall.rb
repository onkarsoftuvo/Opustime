class Recall < ActiveRecord::Base
  belongs_to :patient
  
  has_one :recall_types_recall , :dependent=> :destroy
  has_one :recall_type , :through=> :recall_types_recall , :dependent=> :destroy
  
  accepts_nested_attributes_for :recall_types_recall , :reject_if => lambda { |a| a[:recall_type_id].nil? || a[:recall_type_id].blank?  }, :allow_destroy => true
  validates_presence_of :recall_types_recall
  
  scope :active_recall, ->{ where(status: true)}
  
  before_save :set_current_user_to_recall 
  
  
  def set_current_user_to_recall
    current_user = Thread.current[:user] 
    self.created_by_id = current_user.id
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  def self.to_csv(options = {})
    column_names = ["RECALL ON" ,"TYPE" , "PATIENT",
     "PRACTITIONER" , "PHONE" , "IS SELECTED" , "NOTES"]   
      CSV.generate(options) do |csv|
        csv << column_names
        all.each do |recall|
          data = [] 
          data << recall.recall_on_date.strftime("%d %b %Y")
          data << recall.try(:recall_type).try(:name)
          data << recall.patient.full_name
          data << recall.patient.last_practitioner
          data << recall.patient.patient_contacts.try(:first).try(:contact_no)
          data << recall.is_selected
          data << recall.notes
          csv << data   # Adding recall record in csv file
        end
      end
  end

  def find_owner
    User.find_by_id(self.created_by_id).try(:full_name)  
  end

end
