class PatientPermission < ActiveRecord::Base
  include PermissionFormat
  belongs_to :owner

  serialize :patient_view , JSON
  serialize :patient_create , JSON
  serialize :patient_edit , JSON
  serialize :patient_delete , JSON
  serialize :patient_sms , JSON
  serialize :patient_archive , JSON

  scope :specific_attr , ->{ select('patient_view , patient_create , patient_edit , patient_delete , patient_sms , patient_archive')}

end
