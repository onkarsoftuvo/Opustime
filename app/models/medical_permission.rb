class MedicalPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner
  serialize :medical_crud, JSON
  scope :specific_attr , ->{ select('medical_crud')}
end
