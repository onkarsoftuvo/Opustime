class PatientsContact < ActiveRecord::Base
  belongs_to :patient
  belongs_to :contact
end
