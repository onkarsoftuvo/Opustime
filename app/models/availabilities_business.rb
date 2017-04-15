class AvailabilitiesBusiness < ActiveRecord::Base
  belongs_to :availability
  belongs_to :business
end
