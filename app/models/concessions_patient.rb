class ConcessionsPatient < ActiveRecord::Base
  belongs_to :concession
  belongs_to :patient
end
